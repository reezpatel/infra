{ lib, ... }:
let
  configBuilder =
    {
      config,
      pkgs,
      ...
    }:
    {
      options.username = lib.mkOption {
        type = lib.types.str;
        default = "reezpatel";
        description = "Username for the primary user";
      };
      options.hostname = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Hostname for the machine";
      };
      options.authorizedKeys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Authorized SSH keys for the primary user";
      };

      config = {
        users.users.${config.username} = {
          name = "${config.username}";
          home =
            if pkgs.stdenv.hostPlatform.isDarwin then
              "/Users/${config.username}"
            else
              "/home/${config.username}";
          shell = pkgs.zsh;
        };

        programs.zsh.enable = true;

        networking = {
          hostName = config.hostname;
        };

        nixpkgs.config = {
          allowUnfree = true;
        };

        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        environment.pathsToLink = [ "/share/zsh" ];

        environment.variables = {
          LC_ALL = "en_US.UTF-8";
          LANG = "en_US.UTF-8";
          TMUX_TMPDIR = "/Users/${config.username}/.local/share/tmux";
        };
      };
    };
in
{
  moduleRegistry.darwin.config = configBuilder;
  moduleRegistry.nixos.config = configBuilder;
}
