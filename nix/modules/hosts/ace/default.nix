# ace — Mac (personal/dev): full mac workstation with embedded/jvm tooling.
{
  inputs,
  self,
  ...
}: {
  flake.darwinConfigurations.ace = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";

    modules = with self.modules.darwin; [
      # Aspects
      base
      home

      # Identity
      (
        {
          config,
          pkgs,
          ...
        }: {
          hostname = "ace";

          environment.variables = {
            OLLAMA_HOST = "192.168.2.5";
            DOCKER_HOST = "tcp://192.168.2.5:2375";
            OPENCODE_DISABLE_CLAUDE_CODE = "1";
            # TODO: Move to files
            OPENCODE_TUI_CONFIG = "/Users/reezpatel/.config/opencode/tui.json";
            LIBRARY_PATH = "${pkgs.libiconv}/lib";
          };

          environment.systemPackages = with pkgs; [
            claude-code
            awscli2
            doctl
            terraform
            pm2
            autossh
            gemini-cli
            codex
            gh
            git-wt
            igraph
            clang-tools
            arduino-cli
            arduino-language-server
            openjdk
            rustc
            cargo
            sqld
            openspec
            antigravity
            docker-compose
            docker
          ];

          homebrew.masApps = {};
          homebrew.brews = [
            "mole"
          ];
          homebrew.casks = [
            "kicad"
            "edouard-claude/tap/snip"
            "alt-tab"
            "bartender"
            "beekeeper-studio"
            "free-download-manager"
            "ghostty"
            "google-chrome"
            "insomnia"
            "meetingbar"
            "obsidian"
            "parsec"
            "raycast"
            "rectangle-pro"
            "rustdesk"
            "slack"
            "visual-studio-code"
            "vlc"
            "whatsapp"
            "zed"
            "zoom"
            "proton-pass"
            "netbird-ui"
            "netbirdio/tap/netbird-ui"
            "leapp"
          ];

          home-manager.users.${config.username} = {...}: {
            age.secrets.private-func.file = ../../../../secerts/private-func.age;
            age.secrets.secrets.file = ../../../../secerts/secrets.age;

            imports = with self.modules.homeManager; [
	            ai
	            editor
            ];
          };
        }
      )
    ];
  };
}
