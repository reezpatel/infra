{...}: {
  flake.homeModules.opencode = {
    config,
    lib,
    pkgs,
    ...
  }: {
    age.secrets.opencode-auth.file = ../../../secerts/opencode-auth.age;

    programs.opencode = {
      enable = true;
      package = pkgs.callPackage ../../pkgs/opencode.nix {};
    };

    xdg.configFile."opencode".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/infra/dotfiles/opencode";

    home.activation.seedOpencodeAuth = lib.hm.dag.entryAfter ["writeBoundary"] ''
      auth_file="${config.home.homeDirectory}/.local/share/opencode/auth.json"
      secret_file="${config.age.secrets.opencode-auth.path}"

      if [ ! -e "$auth_file" ]; then
        if [ -e "$secret_file" ]; then
          $DRY_RUN_CMD mkdir -p "$(dirname "$auth_file")"
          $DRY_RUN_CMD install -m 0600 "$secret_file" "$auth_file"
        else
          echo "Skipping opencode auth seed; agenix secret is not available at $secret_file"
        fi
      fi
    '';
  };
}
