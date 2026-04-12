{...}: {
  flake.modules.firmware_update = {...}: {
    services.fwupd = {
      enable = true;
    };
  };
}
