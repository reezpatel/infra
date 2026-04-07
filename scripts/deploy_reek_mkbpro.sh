#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if command -v darwin-rebuild &> /dev/null; then
  sudo --preserve-env=IMPURITY_PATH,IMPURITY_GROUPS \
    IMPURITY_PATH="$ROOT" \
    IMPURITY_GROUPS="*" \
    darwin-rebuild switch --impure --flake "$ROOT/nix#reez-mkbpro"
else
  sudo --preserve-env=IMPURITY_PATH,IMPURITY_GROUPS \
    IMPURITY_PATH="$ROOT" \
    IMPURITY_GROUPS="*" \
    nix run nix-darwin/master#darwin-rebuild -- switch --impure --flake "$ROOT/nix#reez-mkbpro"
fi
