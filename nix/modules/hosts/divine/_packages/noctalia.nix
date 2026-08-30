inputs: {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    settings = {
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
        start = ["notifications"];
        center = [];
        end = ["clipboard" "privacy" "volume" "brightness" "battery" "cpu" "gpu" "ram" "network" "control-center" "clock"];
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
        start = ["workspaces"];
        center = [];
        end = ["wallpaper" "tray"];
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
}
