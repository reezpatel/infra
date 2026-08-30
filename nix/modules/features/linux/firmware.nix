{...}: {
  # Firmware updates via fwupd.
  #
  # This replaces the previously broken module that set
  # `flake.modules.firmware_update` (missing the class layer) and was never
  # imported anywhere.
  flake.modules.nixos.firmware = {...}: {
    services.fwupd.enable = true;
  };
}
