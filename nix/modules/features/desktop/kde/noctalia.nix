# Noctalia as the Plasma shell: Plasma session = KWin + Noctalia instead of
# plasmashell. The homeManager aspect holds the (compositor-agnostic) Noctalia
# config, shared with the niri session; the nixos aspect masks plasmashell and
# autostarts Noctalia in Plasma sessions.
{ inputs, self, ... }:
{
  flake.modules.homeManager.noctalia =
    { config, ... }:
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      programs.noctalia = {
        enable = true;
        settings = {
          wallpaper = {
            enabled = true;
            fill_mode = "crop";
            directory = "${config.home.homeDirectory}/infra/media";
            default.path = "${config.home.homeDirectory}/infra/media/wallpaper.jpg";
          };
          shell = {
            time_format = "{:%l:%M %p}";
            polkit_agent = true;
          };
          bar.top = {
            position = "top";
            margin_edge = 0;
            margin_ends = 0;
            thickness = 44;
            widget_spacing = 12;
            padding = 24;
            radius = 0;
            shadow = false;
            reserve_space = true;
            auto_hide = false;
            start = [ "notifications" ];
            center = [ ];
            end = [
              "clipboard"
              "privacy"
              "volume"
              "brightness"
              "battery"
              "cpu"
              "gpu"
              "ram"
              "network"
              "control-center"
              "clock"
            ];
          };
          bar.bottom = {
            position = "bottom";
            radius = 0;
            margin_edge = 0;
            margin_ends = 0;
            thickness = 44;
            widget_spacing = 12;
            padding = 24;
            shadow = false;
            reserve_space = true;
            auto_hide = false;
            start = [ "workspaces" ];
            center = [ ];
            end = [
              "wallpaper"
              "tray"
            ];
            capsule_radius = 4;
            capsule_thickness = 1;
          };
          dock = {
            enabled = true;
            position = "left";
            auto_hide = false;
            reserve_space = true;
            icon_size = 24;
            main_axis_padding = 4;
            cross_axis_padding = 4;
            radius = 4;
            item_spacing = 4;
          };
          widget.clock = {
            type = "clock";
            format = "{:%a %b %e} {:%-I:%M %p}";
            tooltip_format = "{:%A, %B %d, %Y}";
          };
          widget.workspaces = {
            type = "workspaces";
            pill_scale = 1.3;
            active_pill_size = 1.6;
          };
          widget.cpu = {
            type = "sysmon";
            stat = "cpu_usage";
            display = "text";
          };
          widget.gpu = {
            type = "sysmon";
            stat = "gpu_vram";
            display = "text";
          };
          widget.ram = {
            type = "sysmon";
            stat = "ram_pct";
            display = "text";
          };
          widget.privacy = {
            hide_inactive = true;
          };
          widget.network = {
            show_label = false;
          };
        };
      };
    };

  flake.modules.nixos.kde_shell =
    { config, ... }:
    {
      # Mask plasmashell system-wide: Plasma sessions run KWin + Noctalia.
      # Restore stock Plasma with: sudo rm /etc/systemd/user/plasma-plasmashell.service
      systemd.tmpfiles.rules = [
        "L+ /etc/systemd/user/plasma-plasmashell.service - - - /dev/null"
      ];

      home-manager.users.${config.username}.imports = [
        self.modules.homeManager.noctalia
        (
          { ... }:
          {
            # XDG autostart: Plasma runs these (niri doesn't), so Noctalia only
            # auto-launches in Plasma sessions.
            xdg.configFile."autostart/noctalia.desktop".text = ''
              [Desktop Entry]
              Type=Application
              Name=Noctalia
              Comment=Noctalia shell (replaces plasmashell)
              Exec=noctalia
              X-KDE-autostart-phase=1
            '';
          }
        )
      ];
    };
}
