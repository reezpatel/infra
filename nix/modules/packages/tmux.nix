{...}: {
  flake.homeModules.tmux = {pkgs, ...}: let
    tmux-menus = pkgs.tmuxPlugins.mkTmuxPlugin {
      pluginName = "tmux-menus";
      version = "unstable";
      src = pkgs.fetchFromGitHub {
        owner = "jaclu";
        repo = "tmux-menus";
        rev = "main";
        hash = "sha256-pqm2CFnaOdi9fpU85uoQoA/V3925liqwElcd/N7LAtQ=";
      };
    };
    power-zoom = pkgs.tmuxPlugins.mkTmuxPlugin {
      pluginName = "tmux-power-zoom";
      version = "unstable";
      src = pkgs.fetchFromGitHub {
        owner = "jaclu";
        repo = "tmux-power-zoom";
        rev = "main";
        hash = "sha256-3nogJO/kpFb5ruzBfSsZbrnGcmy+uFWlxBZn3KkuSmo=";
      };
    };
  in {
    programs.tmux = {
      enable = true;
      extraConfig = ''
        set -g @vim_navigator_mapping_prev ""

        set -g mouse on

        set -g status-interval 3
        set -g repeat-time 500
        set -g display-time 1500

        setw -g mode-keys vi

        bind-key : command-prompt

        # use vim-like keys for splits and windows
        bind-key v split-window -h -c "#{pane_current_path}"
        bind-key h split-window -v -c "#{pane_current_path}"
        bind-key c new-window

        # Terminal colors
        set -g default-terminal "tmux-256color"
        set -sag terminal-features ",*:RGB"
        set -sag terminal-features ",*:usstyle"

        # Enable focus events
        set -g focus-events on

        # Enable gapeless window
        set -g renumber-windows on

        set -g base-index 1
        setw -g pane-base-index 1

        # Change prefix key
        unbind c-b
        set-option -g prefix C-x
        bind C-x send-prefix

        # statusline
        set -g status-left ""
        set -g status-right ""
        set -g status-right-length 100

        set -g @catppuccin_status_modules_right "gitmux date_time"
        set -g @catppuccin_status_modules_left "session"
        set -g @catppuccin_date_time_text " %I:%M %p - %a %d %b"

        set -g status-right "#{E:@catppuccin_status_gitmux}"
        set -agF status-right "#{E:@catppuccin_status_date_time}"

        set -g @catppuccin_status_connect_separator "no"

        set -g @catppuccin_window_default_fill "number"
        set -g @catppuccin_window_text " #W"
        set -g @catppuccin_window_default_text " #W"
        set -g @catppuccin_window_current_fill "number"
        set -g @catppuccin_window_current_text " #W"

        bind r source-file ~/.config/tmux/tmux.conf \; display-message "~/.tmux.conf reloaded"
      '';
      plugins = with pkgs.tmuxPlugins; [
        tmux-menus
        sensible
        better-mouse-mode
        vim-tmux-navigator
        catppuccin
        power-zoom
      ];
    };
  };
}
