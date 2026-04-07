{lib, ...}: {
  options.core = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Primary user's username";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Hostname of the system";
    };
    enableGpu = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether Nvidia GPU support is enabled";
    };
    bareMinimum = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to install a bare minimum set of packages";
    };
    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Authorized SSH keys for the user";
    };
    brewPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Brew packages to install";
    };
    nixPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Nix packages to install";
    };
    brewCasks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Brew casks to install";
    };
    brewMacApps = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = {};
      description = "Mac App Store apps to install";
    };
    xdgConfigFiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Home Manager xdg.configFile entries to link out of store";
    };
    scretXdgConfigFiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Home Manager xdg.configFile entries to link out of store which are part of secret";
    };
    programs = {
      autojump = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install autojump";
      };
    };
  };
}
