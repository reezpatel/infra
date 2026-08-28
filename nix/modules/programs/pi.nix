{inputs, ...}: {
  # System level: binary cache for the pi flake's package builds.
  moduleRegistry.nixos.pi = {
    nix.settings = {
      extra-substituters = [
        "https://pi.cachix.org"
      ];
      extra-trusted-public-keys = [
        "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
      ];
    };
  };

  # User level: pi coding agent, fully managed by home-manager (upstream
  # HM module programs.pi-coding-agent, package from the pi flake).
  #
  # NOTE: ~/.pi/agent/settings.json is now a READ-ONLY symlink into the
  # nix store. Edit `settings` below and rebuild; do not edit the file
  # directly. Runtime-only keys pi tries to persist (e.g.
  # lastChangelogVersion) will simply not be saved.
  flake.homeModules.pi = {pkgs, ...}: {
    programs.pi-coding-agent = {
      enable = true;
      package = inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent;

      settings = {
        theme = "dark";
        defaultProvider = "kimi-coding";
        defaultModel = "k3";
        defaultThinkingLevel = "high";
        packages = [
          "npm:@gotgenes/pi-subagents"
          "npm:pi-model-picker"
          "npm:pi-mcp-extension"
          "npm:pi-lens"
          "npm:pi-simplify"
          "npm:pi-btw"
          "npm:pi-ask-user"
          "npm:pi-zentui"
          "npm:@firstpick/pi-extension-git-footer-status"
          "npm:pi-smart-fetch"
          "npm:pi-web-access"
          "npm:@narumitw/pi-plan-mode"
          "npm:pi-ollama-cloud"
          "npm:pi-kilocode"
          "npm:pi-antigravity"
          "git:github.com/penniey/pi-paste-image"
        ];
      };

      # Declarative alternatives are available when needed:
      #   keybindings = { "tui.editor.cursorUp" = [ "up" "ctrl+p" ]; };
      #   models.providers.ollama = { baseUrl = "..."; models = [...]; };
      #   context = ./AGENTS.md;
    };
  };
}
