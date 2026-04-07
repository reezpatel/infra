{
  description = "NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    core.url = "path:./core";
  };

  outputs = {
    core,
    self,
    nixpkgs,
    ...
  }: let
    system = "aarch64-darwin";
    repoRoot = "/Users/reezpatel/infra";
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINulqFShpHuaL3ngPQ9/tvxYNwYbsNEAsImMEMi7CKq8 reezpatel@Reezs-MacBook-Pro.local"
    ];

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };

    commonPackages = with pkgs; [
      fzf
      vim
      age
      eza
      bat
      fd
      jq
      ripgrep
      tree
      wget
      curl
      tmux
    ];

    workstationPackages = with pkgs; [
      neovim
      direnv
      postgresql.out
      go
      gcc

      ondir

      kubectl
      # glow # Markdown renderer for terminal
      # iftop # Network bandwidth monitor
      #
      nodejs_22
      yarn
      pnpm
      claude-code
      awscli2
      doctl
      # firebase-tools
      terraform
      pm2
      prettier
      autossh
      python311

      autoenv

      nerd-fonts.jetbrains-mono

      # nix formatter for zed
      nil
      nixd
      alejandra
      nixfmt
      terraform-ls
      gopls
      tflint

      golangci-lint
      delve
      gotools
      go-migrate

      opencode

      uv

      gemini-cli

      codex

      gh

      git-wt

      gitsign

      esptool
      mpremote
    ];
  in {
    # --- MacOS hosts --- #
    darwinConfigurations = {
      reez-mkbpro = core.lib.mkDarwin {
        self = self;
        pkgs = pkgs;
        options = {
          hostname = "reez-mkbpro";
          username = "reezpatel";
          authorizedKeys = authorizedKeys;
          brewPackages = [];
          nixPackages =
            commonPackages
            ++ workstationPackages
            ++ (with pkgs; [
              ollama
            ]);
          brewCasks = [];
          xdgConfigFiles = {
            "opencode/opencode.json".source = "${repoRoot}/dotfiles/opencode.json";
            "ghostty/config".source = "${repoRoot}/dotfiles/ghostty";
            "kube/config".source = "${repoRoot}/dotfiles/kubeconfig";
            "nvim".source = "${repoRoot}/dotfiles/nvim";
            "dotfiles/shell_functions.sh".source = "${repoRoot}/dotfiles/shell_functions.sh";
          };
          scretXdgConfigFiles = {
            "dotfiles/saaf-func.sh".source = "${repoRoot}/secerts/saaf-func.age";
          };

          # masApps = [
          #   #  "hidden-bar"   = 1452453066;
          #   #  "wireguard"    = 1451685025;
          # ];
          #

          # brews = [
          #   "helm"
          # ];

          # casks = [
          #   "1password"
          #   "bartender"
          #   "raycast"
          #   "rectangle-pro"
          #   "whatsapp"
          #   "alt-tab"
          #   "zoom"
          #   "ghostty"
          #   "obsidian"
          #   "insomnia"
          #   "postman"
          #   "lens"
          #   "google-chrome"
          #   "beekeeper-studio"
          #   "free-download-manager"
          #   "bruno"
          #   "meetingbar"
          #   "zed"
          #   # "lens"
          #   # "gcloud-cli"
          #   # "linear-linear"
          #   # "the-unarchiver"
          #   # "transmit"
          #   # "aws-vault"
          #   # "iina"
          #   # "ultimaker-cura"
          #   # "aws-vault-binary"
          #   # "visual-studio-code"

          #   # # Development Tools
          #   # "claude"
          #   "insomnia"
          #   # "tableplus"
          #   # "ngrok"
          #   # "postico"
          #   "visual-studio-code"
          #   # "wireshark-app"

          #   "slack"

          #   # # Utility Tools
          #   # "appcleaner"
          #   # "syncthing-app"

          #   # # Entertainment Tools
          #   # "steam"
          #   "vlc"

          #   # # Productivity Tools

          #   # # Browsers
          # ];
        };
      };

      # reez-mkbpro-impure = self.darwinConfigurations.reez-mkbpro.extendModules {
      #   modules = [ { impurity.enable = true; } ];
      # };
    };

    # --- Linux hosts --- #
    # nixosConfigurations = {
    #   skull = mkLinux {
    #     hostname = "skull";
    #     user = "reezpatel";
    #     ip = "192.168.2.2";
    #     corePackages = {
    #       common = true;
    #       agent = true;
    #     };
    #   };

    #   tower = mkLinux {
    #     hostname = "tower";
    #     user = "reezpatel";
    #     ip = "192.168.2.4";
    #     corePackages = {
    #       common = true;
    #       agent = true;
    #     };
    #     extraModules = [ { node.labels = [ "node-type=media" ]; } ];
    #   };

    #   workstation = mkLinux {
    #     hostname = "workstation";
    #     user = "reezpatel";
    #     ip = "192.168.2.5";
    #     corePackages = {
    #       common = true;
    #       agent = true;
    #       workstation = true;
    #     };
    #     extraModules = [ { node.labels = [ "node-type=dev" ]; } ];
    #   };

    #   hub = mkLinux {
    #     hostname = "hub";
    #     user = "reezpatel";
    #     ip = "192.168.2.6";
    #     corePackages = {
    #       common = true;
    #       agent = true;
    #     };
    #     extraModules = [ { node.labels = [ "node-type=gpu" ]; } ];
    #   };

    #   # Raspberry Pi nodes — SD card boot, managed via deploy_rpi.sh
    #   rpi1 = mkPi {
    #     hostname = "rpi1";
    #     user = "reezpatel";
    #     extraModules = [ { node.labels = [ "node-type=stateless" ]; } ];
    #   };
    #   rpi2 = mkPi {
    #     hostname = "rpi2";
    #     user = "reezpatel";
    #     extraModules = [ { node.labels = [ "node-type=stateless" ]; } ];
    #   };
    #   rpi3 = mkPi {
    #     hostname = "rpi3";
    #     user = "reezpatel";
    #     extraModules = [ { node.labels = [ "node-type=stateless" ]; } ];
    #   };
    #   rpi4 = mkPi {
    #     hostname = "rpi4";
    #     user = "reezpatel";
    #     extraModules = [ { node.labels = [ "node-type=stateless" ]; } ];
    #   };
    #   rpi5 = mkPi {
    #     hostname = "rpi5";
    #     user = "reezpatel";
    #     extraModules = [ { node.labels = [ "node-type=stateless" ]; } ];
    #   };
    # };
  };
}
