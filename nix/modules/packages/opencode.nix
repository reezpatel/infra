{...}: {
  flake.homeModules.opencode = {...}: {
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
  };
}
