{...}: {
  flake.homeModules.opencode = {
    config,
    lib,
    ...
  }: {
    age.secrets.opencode-auth.file = ../../../secerts/opencode-auth.age;

    programs.opencode = {
      enable = true;

      settings = {
        autoupdate = false;
        compaction = {
          auto = true;
          prune = true;
          reserved = 10000;
        };
        plugin = [
          "opencode-gemini-auth@latest"
          "@ex-machina/opencode-anthropic-auth"
        ];
        provider = {
          ollama = {
            npm = "@ai-sdk/openai-compatible";
            name = "Ollama (local)";
            options = {
              baseURL = "http://192.168.2.5:11434/v1";
            };
            models = {
              "qwen3:8b" = {
                name = "qwen3:8b";
              };
              "deepseek-r1:8b" = {
                name = "deepseek-r1:8b";
              };
            };
          };
        };
      };
    };

    xdg.configFile."opencode/tui.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/tui.json";
      keybinds = {
        leader = "ctrl+b";
      };
      theme = "tokyonight";
    };

    home.activation.seedOpencodeAuth = lib.hm.dag.entryAfter ["writeBoundary"] ''
      auth_file="${config.home.homeDirectory}/.local/share/opencode/auth.json"
      secret_file="${config.age.secrets.opencode-auth.path}"

      if [ ! -e "$auth_file" ]; then
        if [ -e "$secret_file" ]; then
          $DRY_RUN_CMD mkdir -p "$(dirname "$auth_file")"
          $DRY_RUN_CMD install -m 0600 "$secret_file" "$auth_file"
        else
          echo "Skipping opencode auth seed; agenix secret is not available at $secret_file"
        fi
      fi
    '';
  };
}
