# Adding a Pi to the Netboot Fleet

A step-by-step guide for onboarding one Raspberry Pi (rpi2–rpi7) to network
boot NixOS. No prior knowledge of PXE or iSCSI needed — the boxes below
explain the concepts as you go. The big-picture architecture and the "why"
behind every choice live in [setup-rpi-netboot.md](./setup-rpi-netboot.md).

**Assumptions:** the server (`divergent` @ 192.168.2.68) is running NixOS
with this repo's flake, and the one-time router setup (next-server) is done
(see "One-time setup" below). Everything else is here.

---

## Concepts in 60 seconds

- **Network boot (PXE)**: instead of reading an SD card, the Pi's built-in
  firmware asks the network "where do I get my boot files?" and downloads
  them. *PXE* is just the name of the standard handshake.
- **DHCP**: the thing that hands out IP addresses. Ours also tells clients
  *"for boot files, ask 192.168.2.68"* (that's the `next-server` setting).
- **TFTP**: a dead-simple file-download protocol. The boot files are served
  from a folder on divergent: `/workspace/tftpboot`.
- **iSCSI**: a network disk. The server has big files (`rpi-N.img`) that it
  pretends are hard drives; the Pi connects over the network and uses one as
  if it were a real disk plugged in. Each such "virtual disk" is called a
  **LUN**.
- **The trick**: the Pi never needs an SD card — firmware and kernel come
  from TFTP, and the "hard disk" (root filesystem) comes from iSCSI.

One Pi = one LUN = one entry in the flake. That's the whole model.

---

## One-time setup (already done — skip if adding Pi #3+)

1. Router (MikroTik): `/ip dhcp-server network set [find address=192.168.2.0/24] next-server=192.168.2.68`
2. LUNs + iSCSI targets for all 7 Pis created on divergent (verify in step 2 anyway).
3. `netboot-server` module deployed on divergent.

---

## Per-Pi runbook

Work through these steps top to bottom. Example uses `rpi2`; replace the
number everywhere. Total time: ~30–45 min (mostly waiting on builds).

### Step 1 — Collect the Pi's identity

Every Pi has two identifiers you'll need:

| Identifier | Where to find it | Example |
|---|---|---|
| **Serial** (last 8 chars) | put any Linux SD card in the Pi, boot, run `grep Serial /proc/cpuinfo` — take the **last 8 characters** | `b4f64b8d` |
| **MAC** (ethernet) | same Linux: `ip link` → the `en*`/`eth0` address, lowercase | `dc:a6:32:d8:81:bb` |

(Keep that SD card Linux around for step 7 — the EEPROM tooling lives there.)

Write them down in the fleet table at the bottom of this doc.

### Step 2 — Verify the Pi's LUN and iSCSI target exist

On divergent:

```sh
ssh -p 7272 reezpatel@192.168.2.68
sudo targetcli ls /iscsi
```

You should see `iqn.2026-08.local.infra:rpi-2` with:
- a **portal** `0.0.0.0:3260`
- a **LUN 0** → fileio `rpi-2` (`/workspace/iscsi/rpi-2.img`)
- **two ACLs**: `iqn.2026-08.local.rpi-2:initiator` and `iqn.2026-08.local.infra:divergent`

> ⚠️ **Naming gotcha:** flake hosts are `rpi2` (no hyphen); iSCSI names are
> `rpi-2` (with hyphen). Mixing them up produces the cryptic error
> `login rejected: target error (03/01)`.

If anything is missing (shouldn't be for rpi2–rpi7), create it:

```sh
sudo targetcli /backstores/fileio create name=rpi-2 file_or_dev=/workspace/iscsi/rpi-2.img size=32G write_back=true
sudo targetcli /iscsi create iqn.2026-08.local.infra:rpi-2
sudo targetcli /iscsi/iqn.2026-08.local.infra:rpi-2/tpg1/portals create 0.0.0.0 3260
sudo targetcli /iscsi/iqn.2026-08.local.infra:rpi-2/tpg1/luns create /backstores/fileio/rpi-2
sudo targetcli /iscsi/iqn.2026-08.local.infra:rpi-2/tpg1/acls create iqn.2026-08.local.rpi-2:initiator
sudo targetcli /iscsi/iqn.2026-08.local.infra:rpi-2/tpg1/acls/iqn.2026-08.local.rpi-2:initiator create mapped_lun0_lun0=yes
# and the same for iqn.2026-08.local.infra:divergent (lets the server attach the LUN for installs)
sudo targetcli saveconfig
```

Then vendor the new saveconfig into the repo:

```sh
scp divergent:/etc/target/saveconfig.json nix/modules/hosts/divergent/_target-saveconfig.json  # (sudo cat, fix perms)
```

### Step 3 — Create the host config

Create `nix/modules/hosts/rpi2/default.nix` (copy of rpi1's, changed bits
marked):

```nix
# rpi2 — fleet node on full network boot (Pi 4, serial <SERIAL>):
# firmware over TFTP from divergent, root on iSCSI LUN rpi-2.img.
{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.rpi2 = inputs.nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";

    modules = with self.modules.nixos; [
      base
      rpi-netboot        # the magic: systemd initrd + iSCSI root
      home

      ({config, ...}: {
        hostname = "rpi2";                          # ← change

        netboot = {
          serverIp = "192.168.2.68";                # same for everyone
          initiator = "iqn.2026-08.local.rpi-2:initiator";  # ← change (matches the ACL)
          targetName = "iqn.2026-08.local.infra:rpi-2";     # ← change (this Pi's LUN)
        };

        users.users.reezpatel.linger = true;

        home-manager.users.${config.username}.imports = with self.modules.homeManager; [
          shell
        ];
      })
    ];
  };
}
```

### Step 4 — Register the node on the server

In `nix/modules/hosts/divergent/default.nix`, add to `netboot-server.nodes`:

```nix
nodes = [
  { id = "rpi1"; serial = "b4f64b8d"; mac = "dc:a6:32:d8:81:bb";
    iqn = "iqn.2026-08.local.rpi-1:initiator";
    toplevel = self.nixosConfigurations.rpi1.config.system.build.toplevel; }
  { id = "rpi2"; serial = "<SERIAL>"; mac = "<MAC>";               # ← add this
    iqn = "iqn.2026-08.local.rpi-2:initiator";
    toplevel = self.nixosConfigurations.rpi2.config.system.build.toplevel; }
];
```

The `mac` makes u-boot fetch a per-Pi boot menu (`pxelinux.cfg/01-<mac>`)
so every Pi gets its own kernel cmdline.

### Step 5 — Build and deploy the server

From your Mac (builds happen on divergent, so first builds take a while —
the aarch64 Pi closure runs through emulation; later it's cached):

```sh
git add -A .            # flake sources come from the git tree — new files must be staged!
just deploy-divergent
```

Verify the boot files appeared:

```sh
ssh -p 7272 reezpatel@192.168.2.68 \
  'ls /workspace/tftpboot/<SERIAL>/ && grep kernel /workspace/tftpboot/pxelinux.cfg/01-<MAC-WITH-DASHES>'
```

You should see `Image`, `initrd`, `bcm2711-rpi-4-b.dtb`, and a menu entry
mentioning `rpi2`. (The pxelinux MAC file uses **dashes**: `01-88-a2-9e-22-2c-45`.)

### Step 6 — Install NixOS into the Pi's LUN

```sh
just install-lun rpi2
```

(That SSHes to divergent and runs `scripts/netboot-install-lun.sh`, which
attaches `rpi-2.img` as a local disk, formats it on first run, and copies
the NixOS closure into it. First run ≈ 5 min; refreshes are incremental.)

### Step 7 — Point the Pi's firmware at the network

Boot the Pi once with the **SD-card Linux** still in (this is a one-time
EEPROM setting that survives everything):

```sh
ssh reezpatel@<pi-ip>   # the SD Linux
printf 'BOOT_ORDER=0xf12\nTFTP_IP=192.168.2.68\n' > /tmp/eeprom.cfg
sudo rpi-eeprom-config --apply /tmp/eeprom.cfg
sudo reboot
```

What these mean: `BOOT_ORDER=0xf12` = *try network first, SD card as
fallback* (so a broken network still boots the SD rescue system);
`TFTP_IP` = where the firmware fetches boot files.

> The EEPROM flash needs **two** power cycles: the first applies the update,
> the second actually boots with it.

**If the SD Linux is NixOS** (no `rpi-eeprom-config` installed), the flow is:

```sh
nix shell nixpkgs#raspberrypi-eeprom   # provides the tools + EEPROM images
sudo mkdir -p /mnt/fw && sudo mount /dev/mmcblk0p1 /mnt/fw   # the FAT firmware partition
printf 'BOOT_ORDER=0xf12\nTFTP_IP=192.168.2.68\n' | sudo tee /root/bootconf.txt
sudo BOOTFS=/mnt/fw rpi-eeprom-config --apply /root/bootconf.txt
sudo reboot
```

Gotchas hit in practice:
- `recovery.bin` must land on the **vfat firmware partition**
  (`mmcblk0p1`), not the ext4 root — on NixOS SDs that partition often isn't
  even mounted.
- A self-contained `recovery.bin` (via `--out`) may be ignored; use
  `rpi-eeprom-config --apply`, which stages the full update set properly.
- The config is embedded at *staging* time — editing `bootconf.txt` after
  staging does nothing; re-run `--apply`.
- **u-boot prefers the SD card if one is inserted**: even after the EEPROM
  goes network-first, u-boot's own boot order tries mmc0 before PXE. Remove
  the SD card for a true netboot.

### Step 8 — Boot it

Pull the SD card, plug ethernet + power. On the HDMI screen you'll see,
in order (each stage is normal — don't panic at waiting):

1. A bootloader diagnostics screen (board info, `boot: mode NETWORK`)
2. The rainbow splash for a bit while u-boot loads (~10 s)
3. `U-Boot` text, a DHCP line, `Retrieving file: pxelinux.cfg/01-…`
4. `Loading: ########…` — the kernel (~64 MB) and initrd over TFTP (1–3 min)
5. Linux boot messages (`[ OK ] Started …`), including
   `Attach iSCSI root LUN (iqn.2026-08.local.infra:rpi-2)`
6. Screen clears → NixOS console login prompt

You can watch progress from the server side too:

```sh
ssh -p 7272 reezpatel@192.168.2.68 'sudo journalctl -u dnsmasq -f' | grep -i tftp
```

### Step 9 — Verify

From your Mac:

```sh
ssh -p 7272 reezpatel@<pi-ip> 'hostname; nixos-version; lsblk -o NAME,SIZE,LABEL,MOUNTPOINT'
```

Expect: hostname `rpi2`, current NixOS version, and
`sda1 <32G> NIXOS_ISCSI /` — that's the network disk mounted as root. Done —
the Pi now runs with no SD card.

### Step 10 — Post-boot housekeeping

- **Secrets**: the first boot generated *new* SSH host keys, so agenix
  secrets (netbird key, etc.) encrypted to the old key won't decrypt:
  ```sh
  ssh -p 7272 reezpatel@<pi-ip> 'cat /etc/ssh/ssh_host_ed25519_key.pub'   # new key
  # add it as the rpi2 entry in secerts/secrets.nix, then:
  cd secerts && agenix -r && cd ..
  just deploy-rpi2
  ```
- Update the IP in `scripts/deploy_remote.sh`'s HOSTS map and the README
  fleet table.

---

## Troubleshooting by symptom

| What you see | Meaning | Fix |
|---|---|---|
| Rainbow splash forever | Firmware couldn't load/run u-boot | Is `/workspace/tftpboot/kernel8.img` (u-boot) present on divergent? Re-run `just deploy-divergent` |
| Diagnostics screen, then Debian boots | EEPROM didn't flash yet, or BOOT_ORDER not set | Power-cycle once more; check `rpi-eeprom-config` output on the SD Linux |
| u-boot: `ARP Retry count exceeded` / TFTP from wrong IP | u-boot got the wrong boot server from DHCP | Router `next-server=192.168.2.68` set? (MikroTik command in the infra doc) |
| u-boot stuck at `Enter choice:` | pxelinux.cfg has no timeout | Re-run `just deploy-divergent` (generates `timeout 20`) |
| u-boot: `TFTP error … not found` for pxelinux.cfg paths ending in `default` | normal fallback probing, **not** an error | — (it eventually finds `01-<mac>` or `default`) |
| `[FAILED] Failed to start Attach iSCSI root LUN` | iscsistart failed (IQN typo? server down?) | Check IQNs in the host config vs `targetcli ls /iscsi`; note `rpi-2` hyphen |
| `Timed out waiting for device /dev/disk/by-label/NIXOS_ISCSI` | iSCSI attach didn't produce the disk | Same as above; also check LIO session: `sudo targetcli ls /iscsi` on divergent |
| Emergency mode after root mount | LUN has a different closure than the boot cmdline | Run `just install-lun rpi2` again after every rebuild, then power-cycle |
| Emergency shell says root account locked | same as above — nothing to log into | fix the mismatch, power-cycle |
| `error 15 - session exists` during install-lun | old zombie session on divergent | `sudo systemctl restart iscsi-target` on divergent, or reboot divergent |

More background on each failure mode: [setup-rpi-netboot.md](./setup-rpi-netboot.md#gotchas-archive).

---

## Fleet table

Fill this in as you onboard Pis (rpi1 is live):

| Host | IP | Serial (8) | MAC | LUN | Status |
|---|---|---|---|---|---|
| rpi1 | 192.168.2.84 | b4f64b8d | dc:a6:32:d8:81:bb | rpi-1.img | **netbooting NixOS** |
| rpi2 | 192.168.2.80 | cf9a1868 | 88:a2:9e:22:2c:45 | rpi-2.img | **netbooting NixOS** |
| rpi3 | 192.168.2.82 | 09068024 | dc:a6:32:d8:9e:18 | rpi-3.img | **netbooting NixOS** |
| rpi4 | 192.168.2.83 | 835480c9 | e4:5f:01:ba:33:df | rpi-4.img | **netbooting NixOS** |
| rpi5 | 192.168.2.93 | 7ce2faed | e4:5f:01:82:ae:e4 | rpi-5.img | **netbooting NixOS** |
| rpi6 | 192.168.2.88 | 3fbee5af | e4:5f:01:b5:ee:47 | rpi-6.img | **netbooting (firmware-direct, no u-boot)** |
| rpi7 | 192.168.2.81 | 032354f6 | 88:a2:9e:22:2b:6d | rpi-7.img | **netbooting (firmware-direct, no u-boot)** |
