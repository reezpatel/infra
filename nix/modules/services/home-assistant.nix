{...}: {
  flake.modules.nixos.home-assistant = {...}: {
    networking.firewall.allowedTCPPorts = [8123];

    services.home-assistant = {
      enable = true;
      extraComponents = [
        "analytics"
        "apple_tv"
        "flux_led"
        "wiz"
        "google_translate"
        "met"
        "radio_browser"
        "shopping_list"
        "isal"
        "esphome"
        "prometheus"
      ];

      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = {};
      };
    };
  };
}
