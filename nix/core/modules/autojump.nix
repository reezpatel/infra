{
  config,
  lib,
  ...
}: let
  user = config.core.username;
in
  lib.mkIf config.core.programs.autojump {
    home-manager.users.${user}.programs.autojump = {
      enable = true;
    };
  }
