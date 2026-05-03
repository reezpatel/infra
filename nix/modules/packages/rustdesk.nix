{...}: {
  flake.homeModules.rustdesk = {
    lib,
    pkgs,
    ...
  }: let
    server = "trinity";
    clientConfig = ''
      rendezvous_server = '${server}:21116'
      nat_type = 1
      serial = 0

      [options]
      custom-rendezvous-server = '${server}'
      relay-server = '${server}'
      key = ""
    '';
  in {
    home.packages = lib.mkIf pkgs.stdenv.isLinux [
      pkgs.rustdesk
    ];

    xdg.configFile."rustdesk/RustDesk2.toml".text = clientConfig;

    home.file."Library/Application Support/RustDesk/config/RustDesk2.toml" = lib.mkIf pkgs.stdenv.isDarwin {
      text = clientConfig;
    };
  };
}
