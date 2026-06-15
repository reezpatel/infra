# Generate a SCRAM-SHA-256 hash for a password/string.
#
# Usage:
#   just scram 'secure_password123!'

set shell := ["nu", "-c"]

default:
  @just --list

scram password:
  ./scripts/scram_sha_256.py "{{password}}"

update: update-flake update-packages update-helium

update-flake:
  #!/usr/bin/env bash
  set -euo pipefail

  cd nix
  nix flake update

update-packages:
  #!/usr/bin/env bash
  set -euo pipefail

  cd nix

  current_system="$(nix eval --raw --impure --expr builtins.currentSystem)"

  systems=(
    x86_64-linux
    aarch64-linux
    aarch64-darwin
    x86_64-darwin
  )

  packages="$(
    for system in "${systems[@]}"; do
      nix eval --raw ".#packages.$system" \
        --apply "packages: builtins.concatStringsSep \"\n\" (map (attr: \"$system \" + attr) (builtins.attrNames packages))" \
        2>/dev/null || true
    done | sort -u
  )"

  if [[ -z "$packages" ]]; then
    echo "No flake package outputs found for nix-update."
    echo "nix flake update already updated flake inputs and lock hashes."
    exit 0
  fi

  while read -r system attr; do
    [[ -z "$system" || -z "$attr" ]] && continue
    if [[ "$system" != "$current_system" ]]; then
      echo "Skipping $attr for $system on $current_system."
      echo "Run this recipe on a $system machine, or configure a trusted remote builder for $system."
      continue
    fi

    args=()
    case "$attr" in
      stash-bin)
        args+=(--version-regex 'v([0-9].*)')
        ;;
    esac
    nix-update --flake --system "$system" --option extra-platforms "$system" "${args[@]}" "$attr"
  done <<< "$packages"

update-helium:
  ./scripts/update_helium.py

update-package attr system="x86_64-linux":
  #!/usr/bin/env bash
  set -euo pipefail

  cd nix
  current_system="$(nix eval --raw --impure --expr builtins.currentSystem)"
  if [[ "{{system}}" != "$current_system" ]]; then
    echo "Cannot update {{attr}} for {{system}} from $current_system without a trusted {{system}} builder."
    echo "Run this on a {{system}} machine, or configure Nix trusted-users/remote builders."
    exit 1
  fi

  args=()
  case "{{attr}}" in
    stash-bin)
      args+=(--version-regex 'v([0-9].*)')
      ;;
  esac
  nix-update --flake --system "{{system}}" --option extra-platforms "{{system}}" "${args[@]}" "{{attr}}"

kill-builds:
  #!/usr/bin/env bash
  set -euo pipefail

  hosts=(
    192.168.2.2
    192.168.2.4
    192.168.2.5
    192.168.2.6
    192.168.2.7
    192.168.2.80
    192.168.2.81
    192.168.2.82
    192.168.2.83
    192.168.2.84
    168.144.27.142
  )

  for host in "${hosts[@]}"; do
    just kill-builds-on "$host" &
  done
  wait

kill-builds-on host:
  #!/usr/bin/env bash
  set -euo pipefail

  ssh "reezpatel@{{host}}" '
    pkill -TERM -f "nix --extra-experimental-features nix-command flakes build" || true
    sleep 2
    pkill -TERM -f "default-builder.sh" || true
  ' || true

[parallel]
deploy: deploy-trinity deploy-vixen deploy-divine deploy-muse deploy-helix deploy-rpi1 deploy-rpi2 deploy-rpi3 deploy-rpi4 deploy-rpi5 deploy-slayer

deploy-trinity action="switch":
  ./scripts/deploy_remote.sh trinity "{{action}}"

switch-trinity-current:
  ssh -t reezpatel@192.168.2.2 'sudo NIXOS_NO_CHECK=1 /nix/var/nix/profiles/system/bin/switch-to-configuration switch'

deploy-vixen action="switch":
  ./scripts/deploy_remote.sh vixen "{{action}}"

deploy-divine action="switch":
  ./scripts/deploy_remote.sh divine "{{action}}"

deploy-muse action="switch":
  ./scripts/deploy_remote.sh muse "{{action}}"

deploy-helix action="switch":
  ./scripts/deploy_remote.sh helix "{{action}}"

deploy-rpi1 action="switch":
  ./scripts/deploy_remote.sh rpi1 "{{action}}"

deploy-rpi2 action="switch":
  ./scripts/deploy_remote.sh rpi2 "{{action}}"

deploy-rpi3 action="switch":
  ./scripts/deploy_remote.sh rpi3 "{{action}}"

deploy-rpi4 action="switch":
  ./scripts/deploy_remote.sh rpi4 "{{action}}"

deploy-rpi5 action="switch":
  ./scripts/deploy_remote.sh rpi5 "{{action}}"

deploy-slayer action="switch":
  ./scripts/deploy_remote.sh slayer "{{action}}"

deploy-mac host="ace":
  ./scripts/deploy_macos.sh "{{host}}"
