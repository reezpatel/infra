{ config, ... }:
let
  user = config.core.username;
in
{
  environment.pathsToLink = [ "/share/zsh" ];

  environment.variables = {
    KUBECONFIG = "/Users/${user}/.config/kube/config";
    LC_ALL = "en_US.UTF-8";
    LANG = "en_US.UTF-8";
    OLLAMA_HOST = "192.168.2.5";
    TMUX_TMPDIR = "/Users/${user}/.local/share/tmux";
    OPENCODE_DISABLE_CLAUDE_CODE = "1";
    OPENCODE_TUI_CONFIG = "/Users/${user}/.config/opencode/tui.json";
  };

  launchd.user.agents.tmux-tmpdir = {
    script = ''
      mkdir -p /Users/${user}/.local/share/tmux
      chmod 700 /Users/${user}/.local/share/tmux
    '';
    serviceConfig = {
      RunAtLoad = true;
      Label = "dev.${user}.tmux-tmpdir";
    };
  };
}
