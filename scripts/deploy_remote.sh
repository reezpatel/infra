#!/usr/bin/env bash
#
FLAKE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REMOTE_FLAKE="infra"
OLD_REMOTE_FLAKE="infra-nixos"

declare -A HOSTS=(
  [trinity]="192.168.2.2"
  [vixen]="192.168.2.4"
  [divine]="192.168.2.5"
  [muse]="192.168.2.6"
  [helix]="192.168.2.7"
  [rpi1]="192.168.2.80"
  [rpi2]="192.168.2.81"
  [rpi3]="192.168.2.82"
  [rpi4]="192.168.2.83"
  [rpi5]="192.168.2.84"
  [slayer]="147.93.171.18"
)

USERNAME="reezpatel"
# sshd is moving from 22 to 7272 host-by-host; override while migrating:
#   ./scripts/deploy_remote.sh -p 22 muse switch
PORT="7272"
while getopts ":u:p:" opt; do
  case "${opt}" in
    u) USERNAME="${OPTARG}" ;;
    p) PORT="${OPTARG}" ;;
    *) echo "Usage: $0 [-u username] [-p port] <hostname> [switch|boot|test|build]"; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 [-u username] [-p port] <hostname> [switch|boot|test|build]"
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
echo "==> Deploying ${HOSTNAME} → ${USERNAME}@${HOST_IP}:${PORT} (${ACTION})"
export NIX_SSHOPTS="-p ${PORT}"

echo "==> Syncing infra..."
ssh -p "${PORT}" "${USERNAME}@${HOST_IP}" "if [ -e /infra-nixos ]; then sudo rm -rf /infra-nixos; fi; if [ -e ~/${OLD_REMOTE_FLAKE} ]; then rm -rf ~/${OLD_REMOTE_FLAKE}; fi"
ssh -p "${PORT}" "${USERNAME}@${HOST_IP}" "mkdir -p ~/${REMOTE_FLAKE}"
rsync -az --progress --delete -e "ssh -p ${PORT}" \
  --exclude-from="${FLAKE_DIR}/.gitignore" \
  --exclude='.git' \
  --exclude='.terraform' \
  --exclude='dotfiles/opencode/node_modules' \
  --exclude='.opencode/nnode_modules' \
  --exclude='result*' \
  "${FLAKE_DIR}/" \
  "${USERNAME}@${HOST_IP}:${REMOTE_FLAKE}/"

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
  nh os "${ACTION}" ${FLAKE_DIR}/nix#${HOSTNAME} --target-host "${USERNAME}@${HOST_IP}" --build-host "${USERNAME}@${HOST_IP}" --hostname "${HOSTNAME}"
else
  nix run nixpkgs#nh -- os "${ACTION}" ${FLAKE_DIR}/nix#${HOSTNAME} --target-host "${USERNAME}@${HOST_IP}" --build-host "${USERNAME}@${HOST_IP}" --hostname "${HOSTNAME}"
fi



# nixos-rebuild switch --flake .#my-nixos \
  # --target-host root@192.168.4.1 --build-host localhost --verbose
