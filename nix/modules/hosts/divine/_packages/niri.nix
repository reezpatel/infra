inputs: {pkgs, ...}: {
  imports = [
    inputs.niri.homeModules.config
  ];

  # niri-flake pins niri-stable v25.08, which references libdisplay-info_0_2
  # (removed from nixpkgs). Use nixpkgs' niri instead — the same version the
  # NixOS module (programs.niri.enable) actually runs — so config validation
  # matches the running compositor.
  programs.niri.package = pkgs.niri;

  programs.niri.settings = {
    environment = {
      GTK_THEME = "Colloid-Dark";
      COLOR_SCHEME = "prefer-dark";
    };

    xwayland-satellite.path = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";

    spawn-at-startup = [
      {sh = "swaybg -i \"$HOME/infra/media/bg-dark.jpg\" -m fill";}
      {argv = ["noctalia"];}
      {argv = ["nsticky"];}
    ];

    prefer-no-csd = true;

    outputs."DP-5" = {
      mode = {
        width = 3840;
        height = 2160;
        refresh = 59.997;
      };
      scale = 1.25;
      position = {
        x = 0;
        y = 0;
      };
      transform.rotation = 0;
    };

    outputs."HDMI-A-1" = {
      enable = false;
    };

    outputs."DP-5" = {
      enable = false;
    };

    input.keyboard.xkb.layout = "us";

    binds = {
      "Mod+Space".action.spawn = "walker";
      "Mod+Shift+Space".action.spawn-sh = "noctalia msg panel-toggle launcher";
      "Mod+Shift+V".action.spawn-sh = "noctalia msg panel-toggle clipboard";
      "Mod+Comma".action.spawn-sh = "noctalia msg settings-toggle";
      "Ctrl+Alt+Super+Space".action.toggle-overview = [];
      "Mod+Shift+Q".action.close-window = [];
      "Mod+Shift+E".action.quit = [];
      "Mod+Shift+1".action.spawn = [
        "ndrop"
        "--focus"
        "--class"
        "kitty"
        "kitty"
      ];
      "Mod+Shift+2".action.spawn = [
        "ndrop"
        "--focus"
        "--class"
        "dev.zed.Zed"
        "zeditor"
      ];
      "Mod+Shift+3".action.spawn = [
        "ndrop"
        "--focus"
        "helium"
      ];
      "Mod+Shift+4".action.spawn-sh = "filename=\"$HOME/Pictures/screenshot-$(date +%Y-%m-%d-%H%M%S).png\" && grim -g \"$(slurp)\" \"$filename\" && wl-copy < \"$filename\" && notify-send \"Screenshot saved\" \"$(basename \"$filename\")\"";

      "Mod+Page_Down".action.focus-workspace-down = [];
      "Mod+Page_Up".action.focus-workspace-up = [];
      "Mod+Shift+Page_Down".action.move-window-to-workspace-down = [];
      "Mod+Shift+Page_Up".action.move-window-to-workspace-up = [];

      "Ctrl+Alt+Super+Left".action.focus-column-left = [];
      "Ctrl+Alt+Super+Right".action.focus-column-right = [];
      "Ctrl+Alt+Super+Up".action.focus-window-up = [];
      "Ctrl+Alt+Super+Down".action.focus-window-down = [];
      "Ctrl+Alt+Super+T".action.spawn = [
        "ndrop"
        "--focus"
        "--class"
        "kitty"
        "kitty"
      ];
      "Ctrl+Alt+Super+Shift+Left".action.move-column-left = [];
      "Ctrl+Alt+Super+Shift+Right".action.move-column-right = [];
      "Ctrl+Alt+Super+Shift+Up".action.move-window-up = [];
      "Ctrl+Alt+Super+Shift+Down".action.move-window-down = [];
      "Ctrl+Alt+Super+F".action.spawn = "nfsm-cli";
      "Ctrl+Alt+Super+Return".action.toggle-window-floating = [];
      "Ctrl+Alt+Super+R".action.switch-preset-column-width = [];
      "Ctrl+Alt+Super+Shift+R".action.switch-preset-window-height = [];
      "Ctrl+Alt+Super+C".action.consume-window-into-column = [];
      "Ctrl+Alt+Super+E".action.expel-window-from-column = [];
      "Ctrl+Alt+Super+Page_Up".action.focus-workspace-up = [];
      "Ctrl+Alt+Super+Page_Down".action.focus-workspace-down = [];
      "Ctrl+Alt+Super+Shift+Page_Up".action.move-window-to-workspace-up = [];
      "Ctrl+Alt+Super+Shift+Page_Down".action.move-window-to-workspace-down = [];

      "XF86AudioRaiseVolume" = {
        action.spawn-sh = "noctalia msg volume-up";
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action.spawn-sh = "noctalia msg volume-down";
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action.spawn-sh = "noctalia msg volume-mute";
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        action.spawn = [
          "wpctl"
          "set-mute"
          "@DEFAULT_AUDIO_SOURCE@"
          "toggle"
        ];
        allow-when-locked = true;
      };
      "XF86AudioPlay" = {
        action.spawn = [
          "playerctl"
          "play-pause"
        ];
        allow-when-locked = true;
      };
      "XF86AudioPrev" = {
        action.spawn = [
          "playerctl"
          "previous"
        ];
        allow-when-locked = true;
      };
      "XF86AudioNext" = {
        action.spawn = [
          "playerctl"
          "next"
        ];
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        action.spawn-sh = "noctalia msg brightness-down";
        allow-when-locked = true;
      };
      "XF86MonBrightnessUp" = {
        action.spawn-sh = "noctalia msg brightness-up";
        allow-when-locked = true;
      };
    };

    window-rules = [
      {
        geometry-corner-radius = {
          top-left = 10.0;
          top-right = 10.0;
          bottom-left = 10.0;
          bottom-right = 10.0;
        };
        clip-to-geometry = true;
      }
      {
        matches = [{title = "^Picture in picture$";}];
        open-floating = true;
      }
      {
        matches = [{app-id = "dev.noctalia.Noctalia";}];
        open-floating = true;
        default-column-width = {
          fixed = 1080;
        };
        default-window-height = {
          fixed = 920;
        };
      }
    ];

    layer-rules = [
      {
        matches = [{namespace = "^noctalia-wallpaper*";}];
        place-within-backdrop = true;
      }
      {
        matches = [{namespace = "^noctalia-(background|launcher-overlay|dock)-.*$";}];
      }
      {
        matches = [{namespace = "^noctalia-bar-(top|bottom)-.*$";}];
      }
    ];

    layout = {
      gaps = 4;
      background-color = "transparent";
      always-center-single-column = true;

      struts = {
        left = 24;
        right = 24;
        top = 16;
        bottom = 16;
      };

      preset-window-heights = [
        {proportion = 0.33333;}
        {proportion = 0.5;}
        {proportion = 0.66667;}
      ];

      focus-ring = {
        width = 1;
      };

      border = {
        width = 1;
      };
    };

    overview.workspace-shadow.enable = false;

    debug = {
      honor-xdg-activation-with-invalid-serial = [];
    };
  };
}
