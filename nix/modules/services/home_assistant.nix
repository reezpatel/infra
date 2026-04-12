{...}: {
  moduleRegistry.nixos.home_assistant = {...}: {
    services.home-assistant = {
      enable = true;
      extraComponents = [
        # Components required to complete the onboarding
        "analytics"
        "apple_tv"
        "wiz"
        "google_translate"
        "met"
        "radio_browser"
        "shopping_list"
        # Recommended for fast zlib compression
        # https://www.home-assistant.io/integrations/isal
        "isal"
        "esphome"
      ];

      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = {};
      };
    };
  };
}
