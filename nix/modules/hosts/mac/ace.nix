{
  inputs,
  self,
  ...
}: let
  system = "aarch64-darwin";
in {
  flake.darwinConfigurations.ace = inputs.darwin.lib.darwinSystem {
    inherit system;

    modules = [
      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.home-manager.darwinModules.home-manager

      self.darwinModules.config
      self.darwinModules.macosConfig
      self.darwinModules.homebrew
      self.darwinModules.shellAlias
      self.darwinModules.shellFunctions

      self.darwinModules.commonPackages
      self.darwinModules.advancedPackages

      ({pkgs, ...}: {
        nixpkgs.config.allowUnfree = true;

        username = "reezpatel";
        hostname = "ace";
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8 reezpatel@Reezs-MacBook-Pro.local"
        ];

        environment.variables = {
          OLLAMA_HOST = "192.168.2.5";
          OPENCODE_DISABLE_CLAUDE_CODE = "1";
          # TODO: Move to files
          OPENCODE_TUI_CONFIG = "/Users/reezpatel/.config/opencode/tui.json";
        };

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "before-hm";

          users.reezpatel = {...}: {
            age.secrets.private-func.file = ../../../../secerts/private-func.age;

            home = {
              stateVersion = "26.05";
            };

            imports = [
              inputs.agenix.homeManagerModules.default
              self.homeModules.zsh
              self.homeModules.tmux
              self.homeModules.vim
              self.homeModules.nvim
              self.homeModules.git
              self.homeModules.autojump
              self.homeModules.opencode
              self.homeModules.ghostty
              self.homeModules.fastfetch
            ];
          };
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
        ];

        homebrew.masApps = {};
        homebrew.brews = [];
        homebrew.casks = [
          "1password"
          "alt-tab"
          "bartender"
          "beekeeper-studio"
          "bruno"
          "free-download-manager"
          "ghostty"
          "google-chrome"
          "insomnia"
          "lens"
          "meetingbar"
          "obsidian"
          "postman"
          "raycast"
          "rectangle-pro"
          "slack"
          "visual-studio-code"
          "vlc"
          "whatsapp"
          "zed"
          "zoom"
        ];
      })
    ];
  };
}
