{ ... }: {
  # Feature: ollama (homeManager) — ollama CLI client.
  #
  # The client only; used to talk to the ollama server on divine
  # (see the nixos `ollama` feature, OLLAMA_HOST=192.168.2.5 on the macs).
  flake.modules.homeManager.ollama = { pkgs, ... }: {
    home.packages = [ pkgs.ollama ];
  };
}
