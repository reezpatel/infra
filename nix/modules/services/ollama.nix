{...}: {
  moduleRegistry.nixos.ollama = {pkgs, ...}: {
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      port = 11434;
      package = pkgs.ollama-cuda;
      environmentVariables = {
        "OLLAMA_ORIGINS" = "*";
      };
    };
  };
}
