#!/usr/bin/env bash
# netboot-install-lun.sh — install (or refresh) a netbooted NixOS node into
# its iSCSI LUN.
#
# Run as root ON the netboot server (divergent):
#   sudo ./scripts/netboot-install-lun.sh rpi1
#
# How it works (and why not nixos-install):
#   nixos-install tries to build/activate inside the mounted aarch64 target
#   and fights the x86_64 host. Instead we do the equivalent by hand:
#     1. attach the node's LUN locally via iscsiadm (iscsid-managed sessions
#        can be logged out again; iscsistart ones cannot)
#     2. on first run: partition + mkfs; on re-runs: keep the filesystem
#     3. nix copy the node's closure into the LUN store (incremental)
#     4. point /nix/var/nix/profiles/system at the closure
#   The first boot then runs activation itself (the kernel cmdline's init=
#   points straight at the closure in the LUN).
set -euo pipefail

NODE="${1:?usage: netboot-install-lun.sh <node-id> e.g. rpi1}"
SERVER_IP="${SERVER_IP:-192.168.2.7}"
INITIATOR="${INITIATOR:-iqn.2026-08.local.infra:divergent}"
# Hosts are rpi1..rpi7 but LIO targets/backstores are named rpi-1..rpi-7.
TARGET="${TARGET:-iqn.2026-08.local.infra:${NODE/rpi/rpi-}}"
LABEL="${LABEL:-NIXOS_ISCSI}"
FLAKE="${FLAKE:-/home/reezpatel/infra/nix}"
MNT="/mnt/${NODE}-install"

echo "==> installing $NODE into LUN $TARGET (flake $FLAKE)"

if [ "$(id -u)" -ne 0 ]; then
  echo "must run as root" >&2
  exit 1
fi

TL="$(cd "$FLAKE" && nix path-info --impure ".#nixosConfigurations.${NODE}.config.system.build.toplevel")"
echo "==> closure: $TL"

dev=""
cleanup() {
  set +e
  if mountpoint -q "$MNT"; then umount -R "$MNT"; fi
  rmdir "$MNT" 2>/dev/null
  if [ -n "$dev" ]; then
    "$ISC_BIN/iscsiadm" -m node -T "$TARGET" -p "${SERVER_IP}:3260" -u >/dev/null 2>&1
    udevadm settle
    echo "==> iscsi session detached"
  fi
}
trap cleanup EXIT

# --- attach the LUN (iscsid-managed so repeated runs stay clean) ----------
ISC_BIN="$(ls -d /nix/store/*-open-iscsi-*/bin 2>/dev/null | head -n1)"
mkdir -p /var/run/iscsi /etc/iscsi
echo "InitiatorName=$INITIATOR" >/etc/iscsi/initiatorname.iscsi
[ -f /etc/iscsi/iscsid.conf ] || : >/etc/iscsi/iscsid.conf
pgrep -x iscsid >/dev/null 2>&1 || "$ISC_BIN/iscsid" 2>/dev/null || true
"$ISC_BIN/iscsiadm" -m discovery -t sendtargets -p "${SERVER_IP}:3260" >/dev/null
# Login is idempotent: an existing session to this target is reused.
"$ISC_BIN/iscsiadm" -m node -T "$TARGET" -p "${SERVER_IP}:3260" -l >/dev/null 2>&1 || true

# Identify the LUN via its stable by-path link (no lsblk before/after races).
dev=""
for _ in $(seq 1 30); do
  link="$(find /dev/disk/by-path -maxdepth 1 -name "ip-${SERVER_IP}:3260-iscsi-${TARGET}-lun-0" 2>/dev/null | head -n1 || true)"
  if [ -n "$link" ] && [ -b "$link" ]; then
    dev="$(readlink -f "$link")"
    break
  fi
  sleep 1
done
if [ -z "$dev" ] || [ ! -b "$dev" ]; then
  echo "LUN did not appear as a block device" >&2
  exit 1
fi
echo "==> LUN attached as $dev ($(lsblk -ndo SIZE "$dev"))"

part="${dev}1"
[ -b "$part" ] || part="${dev}p1"

# --- filesystem: create once, keep on re-runs -----------------------------
mkdir -p "$MNT"
RESUME=0
if mount "$part" "$MNT" 2>/dev/null && [ "$(ls "$MNT/nix/store" 2>/dev/null | wc -l)" -gt 100 ]; then
  echo "==> existing install found, refreshing (no re-format)"
  RESUME=1
else
  umount "$MNT" 2>/dev/null || true
  wipefs -a "$dev"
  sgdisk -Z "$dev" >/dev/null
  sgdisk -n 1:0:0 -t 1:8300 -c 1:"root" "$dev" >/dev/null
  partprobe "$dev"
  udevadm settle
  part="${dev}1"
  [ -b "$part" ] || part="${dev}p1"
  mkfs.ext4 -F -L "$LABEL" "$part"
  mount "$part" "$MNT"
fi

# --- install the closure ----------------------------------------------------
echo "==> copying closure (incremental, first run takes a few minutes)"
nix copy --no-check-sigs --to "local?root=$MNT" "$TL"

mkdir -p "$MNT/nix/var/nix/profiles" "$MNT/etc" "$MNT/run" "$MNT/boot" "$MNT/etc/ssh"
ln -sfn "$TL" "$MNT/nix/var/nix/profiles/system"
touch "$MNT/etc/NIXOS"

if [ "$RESUME" -eq 1 ]; then
  echo "==> $NODE refreshed; next reboot picks up the new closure"
else
  echo "==> $NODE installed; first boot runs activation itself"
fi
