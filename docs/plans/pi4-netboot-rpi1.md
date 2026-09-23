---
plan name: pi4-netboot-rpi1
plan description: Fleet network boot infrastructure
plan status: done
---

## Idea
Make divergent (192.168.2.68, x86_64 NixOS) a fully declarative netboot server so rpi1 — a Pi 4 Model B rev 1.4, serial 10000000b4f64b8d, currently Debian-on-SD at 192.168.2.84 — boots NixOS entirely from the network: Pi firmware over TFTP (per-serial dirs) with root on the existing iSCSI LUN /workspace/iscsi/rpi-1.img (32G, LIO target iqn.2026-08.local.infra:rpi-1, ACL iqn.2026-08.local.rpi-1:initiator). Design: (a) new `services.target` NixOS module wrapping targetcli restoreconfig (the option is already referenced by divergent's config but the module doesn't exist); (b) new netboot-server module (dnsmasq PXE-proxy/TFTP, per-serial tftpboot layout synced from built aarch64 closures, firewall fixes: UDP 67/69/4011 + TCP 3260); (c) new `rpi-netboot` client aspect with systemd-initrd + iscsistart for iSCSI root (upstream has no boot.initrd.iscsi); (d) NixOS installed into the rpi-1 LUN from divergent via its own iSCSI ACL + binfmt aarch64 emulation; (e) flip rpi1 EEPROM to BOOT_ORDER=0xf12 (network first, SD Debian kept as fallback) + TFTP_PREFIX=1. Remaining 6 Pis follow the same pattern later (LUNs/targets already exist).

## Implementation
- [object Object]
- [object Object]
- [object Object]
- [object Object]
- [object Object]
- [object Object]
- [object Object]

## Required Specs
<!-- SPECS_START -->
<!-- SPECS_END -->