# Generate a SCRAM-SHA-256 hash for a password/string.
#
# Usage:
#   just scram 'secure_password123!'

set shell := ["nu", "-c"]

default:
  @just --list

scram password:
  ./scripts/scram_sha_256.py "{{password}}"

update: update-flake update-packages

update-flake:
  #!/usr/bin/env bash
  set -euo pipefail

  cd nix
  nix flake update

update-packages:
  #!/usr/bin/env bash
  set -euo pipefail

  cd nix

  systems=(
    x86_64-linux
    aarch64-linux
    aarch64-darwin
    x86_64-darwin
  )

  attrs="$(
    for system in "''${systems[@]}"; do
      nix eval --raw ".#packages.$system" \
        --apply 'packages: builtins.concatStringsSep "\n" (builtins.attrNames packages)' \
        2>/dev/null || true
    done | sort -u
  )"

  if [[ -z "$attrs" ]]; then
    echo "No flake package outputs found for nix-update."
    echo "nix flake update already updated flake inputs and lock hashes."
    exit 0
  fi

  while IFS= read -r attr; do
    [[ -z "$attr" ]] && continue
    nix-update --flake "$attr" --build
  done <<< "$attrs"

update-package attr:
  #!/usr/bin/env bash
  set -euo pipefail

  cd nix
  nix-update --flake "{{attr}}" --build

[parallel]
deploy: deploy-trinity deploy-vixen deploy-divine deploy-muse deploy-helix deploy-rpi1 deploy-rpi2 deploy-rpi3 deploy-rpi4 deploy-rpi5 deploy-slayer

deploy-trinity action="switch":
  ./scripts/deploy_remote.sh trinity "{{action}}"

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
