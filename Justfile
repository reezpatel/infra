# Generate a SCRAM-SHA-256 hash for a password/string.
#
# Usage:
#   just scram 'secure_password123!'

set shell := ["nu", "-c"]

default:
  @just --list

scram password:
  ./scripts/scram_sha_256.py "{{password}}"
