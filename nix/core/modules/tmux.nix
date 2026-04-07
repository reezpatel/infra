{
  pkgs,
  config,
  ...
}: let
  user = config.core.username;

  tmux-menus = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-menus";
    version = "unstable";
    src = pkgs.fetchFromGitHub {
      owner = "jaclu";
      repo = "tmux-menus";
      rev = "main";
      hash = "sha256-UPWsa7sFy6P3Jo3KFEvZrz4M4IVDhKI7T1LNAtWqTT4=";
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
  home-manager.users.${user} = {
    programs.tmux = {
      enable = true;
      extraConfig = builtins.readFile ../../../dotfiles/tmux.conf;
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
