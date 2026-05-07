# Nix Repo Best Practices

## Module shape

- Put reusable NixOS modules in `nix/modules/services`, `nix/modules/programs`, or `nix/modules/linux` and export them through `moduleRegistry.nixos.<name>`.
- Put reusable nix-darwin modules in `moduleRegistry.darwin.<name>`.
- Put Home Manager modules in `flake.homeModules.<name>`.
- Hosts should compose modules with `self.nixosModules.<name>`, `self.darwinModules.<name>`, and `self.homeModules.<name>`.
- Keep host files focused on host-specific enablement and options. Put reusable service logic in a module.
- Prefer upstream NixOS/Home Manager modules when available before writing custom systemd units.
- Make module options explicit with `lib.mkOption` when behavior may vary by host.

## nix-update compatibility

- Any custom package with a manually maintained `version`, `src.url`, and `src.hash` should be exported as a flake package under `perSystem.packages.<attr>`.
- Do not hide updateable packages only inside a NixOS/Home Manager module `let` binding. `nix-update --flake <attr>` needs a package output to target.
- If a module needs the same package, define one package function and reuse it for both `perSystem.packages.<attr>` and the module. Do not duplicate version/hash.
- Export package attrs only on systems they can actually build on. For example, an x86_64 Linux binary should only be exposed under `packages.x86_64-linux`.
- Use `rec` derivations when the URL includes `version`.
- URLs should interpolate `${version}` instead of repeating a hardcoded version string.
- Prefer stable attr names such as `stash-bin` or `helium`; these are what `just update-package <attr>` and `nix-update --flake <attr>` use.
- Add useful `meta`, especially `homepage`, `mainProgram`, `license`, and `platforms`.

Example:

```nix
{...}: let
  mkExample = pkgs:
    pkgs.stdenv.mkDerivation rec {
      pname = "example";
      version = "1.2.3";

      src = pkgs.fetchurl {
        url = "https://example.com/releases/v${version}/example-linux";
        hash = "sha256-...";
      };
    };
in {
  perSystem = {lib, pkgs, ...}: {
    packages = lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      example = mkExample pkgs;
    };
  };

  moduleRegistry.nixos.example = {pkgs, ...}: {
    environment.systemPackages = [
      (mkExample pkgs)
    ];
  };
}
```

Then update it with:

```bash
just update-package example x86_64-linux
```

## Updating

- Use `just update` to run `nix flake update` and then update exported flake packages with `nix-update`.
- `nix flake update` updates inputs such as `nixpkgs`, Home Manager, nix-darwin, agenix, and lock hashes.
- Kernel updates come through `nixpkgs`; they apply only after deploying/switching and rebooting the host.
- `nix-update` updates individual package version/hash pairs. It does not update unexported module-local derivations.
- Run `nix-update` for a package on the same system that exports that package, unless Nix has a trusted remote builder or trusted `extra-platforms` for the target system.
- Do not let `nix-update` partially update a foreign-system package from an unsupported local machine. If it bumps `version` but cannot rehash, either run it on the target system or repair the hash with `nix store prefetch-file`.

## Deployment

- Use host-specific Just recipes for individual hosts, for example `just deploy-divine`.
- Use `just deploy` for parallel deployment to all remote NixOS hosts.
- Remote deploy behavior and host/IP mapping live in `scripts/deploy_remote.sh`; update that script when adding or changing remote hosts.
- Darwin deploy behavior lives in `scripts/deploy_macos.sh`; use `just deploy-mac ace` for macOS hosts.
- Do not run remote builds or switches from automation unless the user explicitly asks for it.

## Config files

- Prefer declarative Home Manager files for user config where practical.
- Store reusable config data under `dotfiles/<app>` and read it from modules with structured parsers such as `builtins.fromJSON` when the file format allows it.
- For git flakes, new files must be tracked by git before flake evaluation can see them.

## Services

- Prefer systemd timers over cron.
- For remote sync jobs, use explicit source/target paths, exclude backup/snapshot directories from the main sync, and document required SSH keys.
- For long-running services, define restart behavior, state directories, users, firewall ports, and health/status commands where relevant.


DONT ADD COMMENTS UNLESS ITS REALLY REQUIRED
