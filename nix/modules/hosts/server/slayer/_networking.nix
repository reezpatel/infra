{lib, ...}: {
  # Networking config for Contabo VPS - static IP setup
  networking = {
    nameservers = [
      "8.8.8.8"
      "1.1.1.1"
    ];
    defaultGateway = {
      address = "147.93.171.1";
      interface = "ens18";
    };
    dhcpcd.enable = false;
    useDHCP = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      ens18 = {
        ipv4.addresses = [
          {
            address = "147.93.171.18";
            prefixLength = 32;
          }
        ];
        ipv4.routes = [
          {
            address = "147.93.171.1";
            prefixLength = 32;
          }
        ];
        ipv6.addresses = [
          {
            address = "fe80::250:56ff:fe65:6c7e";
            prefixLength = 64;
          }
        ];
        ipv6.routes = [];
      };
    };
  };

  services.udev.extraRules = ''
    ATTR{address}=="00:50:56:65:6c:7e", NAME="ens18"
  '';
}
