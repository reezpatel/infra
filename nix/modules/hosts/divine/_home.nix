# Home-manager layer for divine: niri/noctalia desktop, flatpak, AI tooling.
# Imported from ./default.nix as `(import ./_home.nix { inherit inputs self; })`.
{
  inputs,
  self,
}: {config, ...}: {
  home-manager.users.${config.username} = {
    pkgs,
    config,
    lib,
    ...
  }: {
    imports =
      [
        (import ./_packages/noctalia.nix inputs)
        (import ./_packages/niri.nix inputs)
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
        inputs.nsticky.homeModules.default
        inputs.nfsm-flake.homeModules.default
      ]
      ++ (with self.modules.homeManager; [
        # shell

        clipboard
      ]);

    home.packages = with pkgs; [
      flatpak
    ];
    home.sessionVariables = {
      XDG_DATA_DIRS = "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:$XDG_DATA_DIRS";
    };

    # Sticky window management (e.g. YouTube picture-in-picture)
    programs.nsticky = {
      enable = true;
      settings = {
        sticky = {
          picture-in-picture.title = "^Picture in picture$";
        };
      };
    };

    services.nfsm.enable = true;

    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
    };

    gtk = {
      enable = true;
      theme = {
        name = "Colloid-Dark";
        package = pkgs.colloid-gtk-theme;
      };
    };

    # KDE's GTK integration rewrites ~/.gtkrc-2.0 at login; without force,
    # HM activation fails once a .before-hm backup already exists. The key
    # must match the gtk module's attr name exactly (absolute configLocation),
    # otherwise it creates a second entry for the same target and the
    # "conflicting managed target files" assertion fires.
    home.file."${config.home.homeDirectory}/.gtkrc-2.0".force = lib.mkForce true;

    xdg.configFile."mako/config".text = ''
      anchor=top-right
      margin=16
      padding=12
      border-size=2
      border-radius=12
      default-timeout=5000
      max-visible=5
      layer=overlay
      font=JetBrainsMonoNL NFM 11

      background-color=#1a1b26ee
      text-color=#c0caf5ff
      border-color=#7aa2f7ff
      progress-color=over #414868ff

      [urgency=high]
      border-color=#f7768eff
      default-timeout=0
    '';

    systemd.user.services.mako = {
      Unit = {
        Description = "Mako notification daemon";
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.mako}/bin/mako";
        Restart = "always";
        RestartSec = 3;
        Type = "simple";
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };

    systemd.user.services.elephant = {
      Unit = {
        Description = "Elephant backend for Walker";
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.elephant}/bin/elephant";
        Restart = "always";
        RestartSec = 3;
        Type = "simple";
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };

    # Flatpak configuration for Orca Slicer
    # Using official Orca Slicer from Flathub instead of Snapmaker fork
    # (Snapmaker version was crashing on startup)
    services.flatpak = {
      enable = true;
      update.auto.enable = true;
      packages = [
        "com.orcaslicer.OrcaSlicer"
        "com.ticktick.TickTick"
      ];

      # Override settings for better graphics performance
      overrides = {
        "com.orcaslicer.OrcaSlicer" = {
          Context = {
            # Enable GPU/graphics access for 3D viewport
            devices = ["dri"];
            # Grant access to graphics drivers
            filesystems = [
              "/run/opengl-driver:ro"
              "/run/opengl-driver-32:ro"
            ];
          };
        };
      };
    };
  };
}
