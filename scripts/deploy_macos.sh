#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if command -v nh &> /dev/null; then
    nh darwin switch "$ROOT/nix#$1"
else
  	nix run nixpkgs#nh darwin switch "$ROOT/nix#$1"
fi
