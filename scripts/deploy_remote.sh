#!/usr/bin/env bash
#
FLAKE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REMOTE_FLAKE="infra-nixos"

declare -A HOSTS=(
  [trinity]="192.168.2.2"
  [vixen]="192.168.2.4"
  [divine]="192.168.2.5"
  [muse]="192.168.2.6"
  [rpi1]="192.168.2.80"
  [rpi2]="192.168.2.81"
  [rpi3]="192.168.2.82"
  [rpi4]="192.168.2.83"
  [rpi5]="192.168.2.84"
)

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <hostname> [switch|boot|test|build]"
  exit 1
fi

HOSTNAME="$1"
shift
ACTION="${1:-switch}"

if [[ -z "${HOSTS[$HOSTNAME]+x}" ]]; then
  echo "Error: unknown hostname '${HOSTNAME}'. Known hosts: ${!HOSTS[*]}"
  exit 1
fi

case "${ACTION}" in
  switch|boot|test|build)
    ;;
  *)
    echo "Error: unsupported action '${ACTION}'. Expected one of: switch boot test build"
    exit 1
    ;;
esac

HOST_IP="${HOSTS[$HOSTNAME]}"
echo "==> Deploying ${HOSTNAME} → ${HOST_IP} (${ACTION})"

echo "==> Syncing infra..."
ssh "reezpatel@${HOST_IP}" "mkdir -p ~/${REMOTE_FLAKE}"
rsync -az --progress --delete --exclude='.git' --exclude='.terraform' --exclude='result*' "${FLAKE_DIR}/" "reezpatel@${HOST_IP}:${REMOTE_FLAKE}/"

echo "==> Running NixOS ${ACTION} on remote host..."
# ssh -t "reezpatel@${HOST_IP}" "
#   set -euo pipefail
#   if command -v nh >/dev/null 2>&1; then
#     nh os switch './${REMOTE_FLAKE}/nix' --hostname '${HOSTNAME}'
#   else
#     nix run nixpkgs#nh -- os switch './${REMOTE_FLAKE}/nix' --hostname '${HOSTNAME}'
#   fi
# "

if command -v nh >/dev/null 2>&1; then
  nh os "${ACTION}" ${FLAKE_DIR}/nix#${HOSTNAME} --target-host "reezpatel@${HOST_IP}" --build-host "reezpatel@${HOST_IP}" --hostname "${HOSTNAME}"
else
  nix run nixpkgs#nh -- os "${ACTION}" ${FLAKE_DIR}/nix#${HOSTNAME} --target-host "reezpatel@${HOST_IP}" --build-host "reezpatel@${HOST_IP}" --hostname "${HOSTNAME}"
fi



# nixos-rebuild switch --flake .#my-nixos \
  # --target-host root@192.168.4.1 --build-host localhost --verbose
