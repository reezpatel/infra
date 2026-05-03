{lib, ...}: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [
      "8.8.8.8"
    ];
    defaultGateway = "168.144.16.1";
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          {
            address = "168.144.27.142";
            prefixLength = 20;
          }
          {
            address = "10.47.0.5";
            prefixLength = 16;
          }
        ];
        ipv6.addresses = [
          {
            address = "fe80::2c2a:dcff:fe69:b687";
            prefixLength = 64;
          }
        ];
        ipv4.routes = [
          {
            address = "168.144.16.1";
            prefixLength = 32;
          }
        ];
        ipv6.routes = [];
      };
      eth1 = {
        ipv4.addresses = [
          {
            address = "10.122.0.2";
            prefixLength = 20;
          }
        ];
        ipv6.addresses = [
          {
            address = "fe80::dc8e:e9ff:feb4:908c";
            prefixLength = 64;
          }
        ];
      };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="2e:2a:dc:69:b6:87", NAME="eth0"
    ATTR{address}=="de:8e:e9:b4:90:8c", NAME="eth1"
  '';
}
