# Raspberry Pi Netboot Infrastructure

This documents the network-boot setup that lets the Pi fleet (rpi1–rpi7,
Raspberry Pi 4 Model B) boot NixOS **with no SD card**, pulling firmware and
kernel over TFTP and using a disk on the server (`divergent`, 192.168.2.68)
as their root filesystem via iSCSI.

Companion runbook for adding a Pi: **[add-new-pi.md](./add-new-pi.md)** —
start there if you just want to onboard a machine.

---

## How a Pi boots in this fleet

```
Pi (no SD card)
 │  EEPROM bootloader (BOOT_ORDER=0xf12 → network first)
 │  1. DHCP: gets an IP (router) + "boot server = divergent" (proxy DHCP + next-server)
 │  2. TFTP: fetches start4.elf / fixup4.dat / config.txt from divergent
 │  3. config.txt says kernel=kernel8.img → fetches u-boot (small!)
 │
 ├─ u-boot (729 KB, does what the firmware can't: boot big kernels)
 │  4. DHCP again, then TFTP pxelinux.cfg/01-<mac> (per-Pi boot menu)
 │  5. TFTP the real kernel (Image), initrd, and device tree
 │
 ├─ NixOS kernel + systemd initrd
 │  6. ip=dhcp → network up
 │  7. iscsi-root.service: iscsistart logs into the Pi's iSCSI target
 │  8. The Pi's LUN appears as /dev/sda (label NIXOS_ISCSI), mounted as /
 │
 └─ NixOS boots from the "network disk"; activation runs; sshd on :7272
```

Total cold-boot time: roughly 2–4 minutes (TFTP transfers dominate).

### Why u-boot in the middle

The Pi firmware cannot start large kernels: a 64 MB uncompressed mainline
`Image` stalls at the rainbow splash, raw **and** gzipped. Raspberry Pi OS
ships ~10 MB gzipped kernels, which is why theirs work. Instead of fighting
this, the firmware loads a tiny u-boot, and u-boot (which happily loads and
relocates any kernel) does the real work via standard PXE.

### Firmware-direct nodes (no u-boot): rpi6

One board in the fleet (rpi6, serial `3fbee5af`) has a broken u-boot
Ethernet driver — its BOOTP broadcasts never reach the wire (packet-capture
verified; firmware and Linux networking work fine). For such boards, the
netboot-server serves a **complete firmware-direct boot set** in the node's
serial directory (`firmwareBoot = true` in the node entry):

- the firmware probes `<serial>/` before the TFTP root, but **only while
  every prefixed probe hits** — one miss drops the prefix for the whole
  boot, so the serial dir carries start4.elf/fixup4.dat/dtb too
- `initramfs initrd 0x08000000` — an **explicit** initrd address. The
  default `followkernel` computes the initrd position from the kernel PE
  header's oversized `image_size` and overshoots; with an explicit address
  the firmware starts the raw 64 MB kernel just fine

Result: rpi6 boots firmware → kernel over TFTP → iSCSI root with no u-boot
and no SD card. The HDMI shows a stale rainbow splash on these boards — the
machine is headless; check `systemctl`/ssh instead of the screen.

### Why iSCSI instead of NFS

The LUNs (`/workspace/iscsi/rpi-*.img`, 32 GB each) were already created on
divergent, and a block device keeps the Pis' NixOS behaviour identical to a
local disk (ext4, journals, no root-squash headaches).

---

## The moving parts (all in this repo)

| File | What it is |
|---|---|
| `nix/modules/features/networking/netboot-server.nix` | **Server side.** dnsmasq (proxy-DHCP + TFTP), firewall, and the `pi-netboot-sync` service that writes the TFTP tree |
| `nix/modules/features/hardware/rpi-netboot.nix` | **Client side** (`rpi-netboot` aspect): systemd initrd, forced iSCSI modules, `iscsi-root.service` |
| `nix/modules/features/hardware/rpi.nix` | `rpi` (SD-card boot tweaks) and `rpi-node` (base+rpi) aspects for the SD-based Pis |
| `nix/modules/hosts/divergent/default.nix` | Host config wiring it together, plus the fleet node list |
| `nix/modules/hosts/divergent/_target-saveconfig.json` | LIO/iSCSI target layout (backstores, targets, ACLs) restored at boot by upstream `services.target` |
| `scripts/netboot-install-lun.sh` | Installs/refreshes a node's NixOS closure into its LUN (run on divergent) |
| `nix/modules/hosts/rpi1/default.nix` | Example netbooted node |

### netboot-server options (on divergent)

```nix
netboot-server = {
  enable = true;
  interface = "eno1";          # LAN NIC dnsmasq listens on
  serverIp  = "192.168.2.68";  # advertised as TFTP server (DHCP opt 66/150 + boot)
  tftpRoot  = "/workspace/tftpboot";
  firmware  = pkgs.raspberrypifw;               # start4.elf, fixup4.dat, dtbs
  uboot     = cross-compiled ubootRaspberryPi4_64bit;
  dtbName   = "bcm2711-rpi-4-b.dtb";

  nodes = [ {
    id      = "rpi1";                        # nixosConfiguration attr
    serial  = "b4f64b8d";                    # last 8 of /proc/cpuinfo Serial
    mac     = "dc:a6:32:d8:81:bb";           # → pxelinux.cfg/01-dca632d881bb
    iqn     = "iqn.2026-08.local.rpi-1:initiator";
    toplevel = self.nixosConfigurations.rpi1.config.system.build.toplevel;
  } ];
};
```

Adding a node to this list + `nixos-rebuild switch` on divergent regenerates
the whole TFTP tree: firmware + u-boot at the root, and per-serial dirs with
`Image`, `initrd`, dtb, and a pxelinux config pointing at them.

### rpi-netboot options (on each Pi)

```nix
netboot = {
  serverIp   = "192.168.2.68";
  initiator  = "iqn.2026-08.local.rpi-1:initiator";  # must match LIO ACL
  targetName = "iqn.2026-08.local.infra:rpi-1";      # this Pi's LUN
  rootLabel  = "NIXOS_ISCSI";
};
```

The aspect forces `boot.initrd.kernelModules = [ iscsi_tcp libiscsi … ]` —
**not** `availableKernelModules`: nothing udev-triggers iSCSI, so the modules
must be loaded unconditionally or the root LUN never appears.

---

## iSCSI layout on divergent (LIO)

Managed declaratively via upstream NixOS `services.target` (nixpkgs'
`nixos/modules/services/networking/iscsi/target.nix`), which writes
`/etc/target/saveconfig.json` from `_target-saveconfig.json` and runs
`rtslib-fb restore` at boot. To change it: edit the JSON (or run `targetcli`
and re-vendor the saved file), then `systemctl restart iscsi-target`.

Naming convention (note the hyphen!):

| Thing | Name pattern | Example |
|---|---|---|
| Backstore image | `/workspace/iscsi/rpi-N.img` | `rpi-1.img` |
| LIO target | `iqn.2026-08.local.infra:rpi-N` | `…infra:rpi-1` |
| Pi initiator | `iqn.2026-08.local.rpi-N:initiator` | `…rpi-1:initiator` |
| Server's own initiator | `iqn.2026-08.local.infra:divergent` | (for LUN installs/rescue) |
| Host in the flake | `rpiN` (no hyphen) | `rpi1` |

Each target has ACLs for **both** its Pi and divergent itself (rw), so the
server can attach LUNs for installs and rescue.

Important details, learned the hard way:

- Portals must be **`0.0.0.0:3260`**, not `[::0]:3260` — IPv6-wildcard
  portals make LIO reject IPv4 logins with a confusing
  `login rejected: target error (03/01)`.
- `MaxConnections` is 8 so a stray session doesn't lock a LUN.
- `iscsistart`-created sessions **cannot be logged out** (kernel limitation);
  only `iscsiadm` (iscsid-managed) sessions can. If a zombie session ever
  wedges things: reboot divergent, or use the iscsiadm flow the install
  script uses.
- Firewall: UDP 67/69/4011 (DHCP/TFTP/PXE), TCP 3260 (iSCSI) — set by the
  netboot-server module.

---

## Network prerequisites (one-time, outside Nix)

The **router must point boot clients at divergent**. On the MikroTik:

```
/ip dhcp-server network set [find address=192.168.2.0/24] next-server=192.168.2.68
```

Optionally also DHCP option 66 = 192.168.2.68 (belt & suspenders). u-boot
prefers the `next-server` (siaddr) field; the Pi firmware additionally uses
its EEPROM `TFTP_IP`.

Each Pi's EEPROM needs (set once, see the runbook):
`BOOT_ORDER=0xf12` (network first, SD fallback) and `TFTP_IP=192.168.2.68`.

---

## Day-2 operations

### Updating a node's NixOS

```sh
just deploy-divergent          # rebuilds node closures too (they're deps of the sync service)
                               # → TFTP tree gets new kernel/initrd/cmdline
just install-lun rpi1          # copies the matching closure into the LUN (incremental)
# power-cycle the Pi (or, if it's running and reachable: just deploy-rpi1)
```

The order matters: the pxelinux `append` line carries
`init=/nix/store/<hash>-…/init` — if the LUN doesn't contain that exact
closure, boot drops to an emergency shell. `install-lun` keeps LUN and TFTP
pointing at the same closure.

For a **running** Pi you can skip the LUN dance: `just deploy-rpi1` switches
it over SSH (it pulls the closure itself); the TFTP tree is only needed at
the next cold boot.

### Where things live on divergent

```
/workspace/tftpboot/           TFTP root (generated — do not edit by hand)
  start4.elf fixup4.dat …      Pi firmware
  kernel8.img                  u-boot (yes, named like a kernel — on purpose)
  config.txt                   tells the firmware to load kernel8.img
  pxelinux.cfg/01-<mac>        per-Pi boot menu (u-boot reads these)
  <serial>/                    per-Pi Image, initrd, dtb
  COMMON/                      firmware copies
/workspace/iscsi/rpi-N.img     the Pis' disks
```

### Rebooting divergent

Everything is declarative and comes back by itself: `iscsi-target` restores
LIO from the saveconfig, `pi-netboot-sync` regenerates the TFTP tree,
dnsmasq restarts. Running Pis survive a server reboot (their root is in RAM's
page cache to a degree, but expect stalls until it's back).

---

## Gotchas archive (why each weird choice exists)

| Symptom | Root cause | Fix in place |
|---|---|---|
| Rainbow splash forever | Firmware can't start 64 MB mainline Image (raw or gzip) | u-boot as `kernel8.img` |
| `login rejected: target error (03/01)` | IQN typo (`rpi1` vs `rpi-1`) or portal `[::0]` | naming convention + `0.0.0.0` portals |
| `iscsistart: Portal Group not set` | missing `-g 1` | short flags: `-i … -t … -a … -p 3260 -g 1` |
| iscsistart "succeeds" but no disk, 90 s timeout | `iscsi_tcp` never loaded (available ≠ loaded) | `boot.initrd.kernelModules` |
| u-boot waits at `Enter choice:` forever | pxelinux config had no `TIMEOUT` | `timeout 20` + `default <label>` |
| u-boot TFTP'd from the router (192.168.2.2) | DHCP `next-server` = router | MikroTik `next-server=192.168.2.68` + option 66 |
| Emergency shell "root account is locked" | LUN closure ≠ pxelinux `init=` path | `install-lun` after every rebuild |
| `nixos-install` fails cross-arch on the LUN | it builds inside the aarch64 chroot | manual `nix copy` + profile symlink; activation runs at first boot |
| aarch64 builds on the Mac | no Linux builders on macOS | build on divergent (`boot.binfmt.emulatedSystems`) |
| Pure-eval can't find `secerts/` | flake is `nix/`, secrets outside it | evaluate from the git repo (rsync with `.git`), or `--impure` |

New-host keys: the first boot generates fresh SSH host keys, so agenix
secrets encrypted to the *old* host key fail (e.g. netbird). Re-key with
`agenix -r` after adding the new public key to `secerts/secrets.nix`.
