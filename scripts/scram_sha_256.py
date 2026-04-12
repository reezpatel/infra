#!/usr/bin/env nix-shell
#! nix-shell -i python3 -p "python3.withPackages (ps: [ps.scramp])"

import base64
import sys

import scramp


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: scram_sha_256.py <password>", file=sys.stderr)
        return 1

    password = sys.argv[1]
    mechanism = scramp.ScramMechanism()
    salt, stored_key, server_key, iteration_count = mechanism.make_auth_info(password)

    print(
        f"SCRAM-SHA-256{iteration_count}:"
        f"{base64.b64encode(salt).decode()}$"
        f"{base64.b64encode(stored_key).decode()}:"
        f"{base64.b64encode(server_key).decode()}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
