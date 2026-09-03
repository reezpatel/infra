{
  self,
  inputs,
  ...
}: {
  flake.modules.nixos.base = {
    pkgs,
    config,
    ...
  }: {
    imports = with self.modules.nixos; [
      linux-base
      common
      monitoring-client
      netbird-client
      home
    ];

    environment.systemPackages = [inputs.agenix.packages.${pkgs.stdenv.system}.default];

    home-manager.users.${config.username}.imports = with self.modules.homeManager; [
      shell
    ];
  };

  flake.modules.darwin.base = {
    pkgs,
    config,
    ...
  }: {
    imports = with self.modules.darwin; [
      darwin-base
      common
      home
    ];

    environment.systemPackages = [inputs.agenix.packages.${pkgs.stdenv.system}.default];

    home-manager.users.${config.username}.imports = with self.modules.homeManager; [
      shell
    ];
  };

  flake.modules.nixos.server = {config, ...}: {
    imports = with self.modules.nixos; [
      base
      nvidia
    ];

    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune.enable = true;
    };

    home-manager.users.${config.username}.imports = with self.modules.homeManager; [
      ai
      development
    ];
  };

  flake.modules.nixos.rpi = {config, ...}: {
    imports = with self.modules.nixos; [
      base
      rpi
    ];

    # home-manager.users.${config.username}.imports = with self.modules.homeManager; [
    # ];
  };

  flake.modules.nixos.workstation = {config, ...}: {
    imports = with self.modules.nixos; [
      server
      desktop
    ];

    home-manager.users.${config.username}.imports = with self.modules.homeManager; [
      labs
    ];
  };

  flake.modules.darwin.macbook = {config, ...}: {
    imports = with self.modules.darwin; [
      base
    ];

    home-manager.users.${config.username}.imports = with self.modules.homeManager; [
      ai
      development
    ];
  };
}
