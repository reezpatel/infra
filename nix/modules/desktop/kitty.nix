{...}: {
  flake.modules.homeManager.kitty = {
    lib,
    pkgs,
    ...
  }: let
    isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  in {
    programs.kitty = {
      enable = true;
      font = {
        name = "JetBrainsMonoNL NFM";
        size =
          if isDarwin
          then 14
          else 11;
      };
      settings = {
        font_features = "JetBrainsMonoNL NFM +liga";

        background_opacity =
          if isDarwin
          then 0.7
          else 1.0;
        dynamic_background_opacity = true;

        scrollback_lines = 100000;

        enable_audio_bell = false;
        visual_bell_duration = 0.0;

        update_check_interval = 0;

        tab_bar_edge = "bottom";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
        tab_activity_symbol = "󰈸";

        cursor_shape = "block";
        cursor_blink_interval = 0;
        cursor_stop_blinking_after = 15.0;

        mouse_hide_wait = 3.0;
        focus_follows_mouse = "no";

        detect_urls = true;
        url_style = "dotted";
        underline_hyperlinks = "hover";

        strip_trailing_spaces = "smart";

        term = "xterm-256color";

        window_padding_width =
          if isDarwin
          then 8
          else 12;

        placement_strategy = "center";
        hide_window_decorations =
          if isDarwin
          then "no"
          else "yes";

        macos_titlebar_color = "background";
        macos_option_as_alt = "left";

        confirm_os_window_close = 0;

        editor = "zed";

        foreground = "#c0caf5";
        background = "#1a1b26";
        selection_foreground = "#1a1b26";
        selection_background = "#7aa2f7";

        cursor = "#c0caf5";

        color0 = "#15161e";
        color1 = "#f7768e";
        color2 = "#9ece6a";
        color3 = "#e0af68";
        color4 = "#7aa2f7";
        color5 = "#bb9af7";
        color6 = "#7dcfff";
        color7 = "#a9b1d6";
        color8 = "#414868";
        color9 = "#f7768e";
        color10 = "#9ece6a";
        color11 = "#e0af68";
        color12 = "#7aa2f7";
        color13 = "#bb9af7";
        color14 = "#7dcfff";
        color15 = "#c0caf5";
      };

      keybindings = {
        "ctrl+shift+enter" = "new_window";
        "ctrl+shift+t" = "new_tab";
        "ctrl+shift+w" = "close_tab";
        "ctrl+shift+right" = "next_tab";
        "ctrl+shift+left" = "previous_tab";
        "ctrl+shift+]" = "next_window";
        "ctrl+shift+[" = "previous_window";
        "ctrl+shift+f" = "kitten hints";
        "ctrl+shift+u" = "kitten unicode_input";
        "ctrl+shift+c" = "copy_to_clipboard";
        "ctrl+shift+v" = "paste_from_clipboard";
        "ctrl+shift+s" = "paste_from_selection";
        "ctrl+shift+equal" = "change_font_size all +2.0";
        "ctrl+shift+minus" = "change_font_size all -2.0";
        "ctrl+shift+backspace" = "change_font_size all 0";
      };
    };
  };
}
