{...}: {
  flake.modules.nixos.ollama = {pkgs, ...}: {
    networking.firewall.allowedTCPPorts = [11434];

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
