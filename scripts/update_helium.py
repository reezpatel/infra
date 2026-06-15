#!/usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 nix

import base64
import hashlib
import re
import sys
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HELIUM_NIX = ROOT / "nix/modules/packages/helium.nix"
PACKAGE_URLS = {
    "amd64": "https://pkg.helium.computer/deb/dists/stable/main/binary-amd64/Packages",
    "arm64": "https://pkg.helium.computer/deb/dists/stable/main/binary-arm64/Packages",
}


def fetch_package_metadata(arch: str) -> dict[str, str]:
    request = urllib.request.Request(
        PACKAGE_URLS[arch],
        headers={"User-Agent": "curl/8.0"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        body = response.read().decode()

    entries = re.split(r"\n\s*\n", body.strip())
    for entry in entries:
        fields: dict[str, str] = {}
        for line in entry.splitlines():
            if ": " in line:
                key, value = line.split(": ", 1)
                fields[key] = value

        if fields.get("Package") == "helium-bin" and fields.get("Architecture") == arch:
            return fields

    raise RuntimeError(f"Could not find helium-bin metadata for {arch}")


def sri_from_hex_sha256(hex_hash: str) -> str:
    raw = bytes.fromhex(hex_hash)
    return "sha256-" + base64.b64encode(raw).decode()


def update_file(version: str, hashes: dict[str, str]) -> bool:
    original = HELIUM_NIX.read_text()
    updated = original

    updated = re.sub(
        r'(x86_64-linux = \{\n\s+debArch = "amd64";\n\s+hash = ")[^"]+(";)',
        rf"\g<1>{hashes['amd64']}\2",
        updated,
    )
    updated = re.sub(
        r'(aarch64-linux = \{\n\s+debArch = "arm64";\n\s+hash = ")[^"]+(";)',
        rf"\g<1>{hashes['arm64']}\2",
        updated,
    )
    updated = re.sub(
        r'(version = ")[^"]+(";)',
        rf"\g<1>{version}\2",
        updated,
        count=1,
    )

    if updated == original:
        return False

    HELIUM_NIX.write_text(updated)
    return True


def main() -> int:
    metadata = {arch: fetch_package_metadata(arch) for arch in PACKAGE_URLS}
    versions = {arch: fields["Version"].removesuffix("-1") for arch, fields in metadata.items()}

    if len(set(versions.values())) != 1:
        for arch, version in versions.items():
            print(f"{arch}: {version}", file=sys.stderr)
        print("Helium versions do not match across architectures.", file=sys.stderr)
        return 1

    version = next(iter(versions.values()))
    hashes = {
        arch: sri_from_hex_sha256(fields["SHA256"])
        for arch, fields in metadata.items()
    }

    changed = update_file(version, hashes)
    print(f"helium {version}")
    for arch, hash_value in hashes.items():
        print(f"{arch}: {hash_value}")
    print("updated helium.nix" if changed else "helium.nix already up to date")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
