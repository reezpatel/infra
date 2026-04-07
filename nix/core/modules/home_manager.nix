{
  config,
  lib,
  agenix,
  ...
}: let
  user = config.core.username;
  outerConfig = config;
in {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-hm";

    users.${user} = {config, ...}: let
      normalizeConfigFile = _name: value:
        if builtins.isAttrs value && value ? source
        then
          value
          // {
            source = config.lib.file.mkOutOfStoreSymlink value.source;
          }
        else if builtins.isString value
        then {
          source = config.lib.file.mkOutOfStoreSymlink value;
        }
        else value;
    in {
      imports = [agenix.homeManagerModules.default];
      home.stateVersion = "25.11";
      age = {
        identityPaths = [
          "${config.home.homeDirectory}/.ssh/id_ed25519"
        ];
        secrets =
          lib.mapAttrs'
          (
            name: value: let
              secretName = builtins.replaceStrings ["/" "."] ["-" "-"] name;
            in {
              name = secretName;
              value = {
                file = value.source;
                path = "${config.xdg.configHome}/${name}";
              };
            }
          )
          outerConfig.core.scretXdgConfigFiles;
      };
      xdg.configFile = builtins.mapAttrs normalizeConfigFile outerConfig.core.xdgConfigFiles;
    };
  };
}
