{...}: {
  flake.modules.darwin.common-homebrew-packages = {...}: {
    homebrew.masApps = {};
    homebrew.brews = [
      "mole"
    ];
    homebrew.casks = [
      "alt-tab"
      "bartender"
      "beekeeper-studio"
      "free-download-manager"
      "ghostty"
      "google-chrome"
      "insomnia"
      "lens"
      "meetingbar"
      "obsidian"
      "parsec"
      "raycast"
      "rectangle-pro"
      "slack"
      "visual-studio-code"
      "vlc"
      "whatsapp"
      "zed"
      "zoom"
      "proton-pass"
      "leapp"
      "docker-desktop"
    ];
  };
}
