{...}: {
  flake.modules.homeManager.ghostty = {
    lib,
    pkgs,
    ...
  }: let
    isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
    ghostty =
      if isDarwin
      then null
      else
        pkgs.stdenvNoCC.mkDerivation {
          pname = "ghostty-gl";
          inherit (pkgs.ghostty) version;

          dontUnpack = true;

          nativeBuildInputs = [
            pkgs.makeWrapper
          ];

          installPhase = ''
            runHook preInstall

            mkdir -p "$out/bin"
            makeWrapper ${lib.getExe pkgs.ghostty} "$out/bin/ghostty" \
              --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.libglvnd pkgs.mesa]}

            cp -rs ${pkgs.ghostty}/share "$out/share"

            runHook postInstall
          '';

          meta = pkgs.ghostty.meta;
        };
  in {
    xdg.configFile."ghostty/config".onChange = lib.mkIf (!isDarwin) (lib.mkForce "");

    programs.ghostty = {
      enable = true;
      package = ghostty;

      settings = {
        font-family = "JetBrainsMonoNL NFM Regular";
        font-size =
          if isDarwin
          then 14
          else 11;
        font-feature = "+liga  # Enable ligatureso";

        theme = "TokyoNight Night";

        cursor-style = "block";
        cursor-click-to-move = true;
        cursor-style-blink = false;

        scrollback-limit = 1000000000;
        adjust-cell-height = "14%";
        custom-shader-animation = true;

        quick-terminal-position = "top";
        quick-terminal-screen = "macos-menu-bar";
        quick-terminal-autohide = false;

        keybind =
          if isDarwin
          then [
            "shift+enter=text:\\n"
            "super+enter=unbind"
            "alt+left=unbind"
            "alt+right=unbind"
            "super+d=unbind"
          ]
          else [
            # Linux: xremap handles Cmd+C/V and terminal navigation remaps.
            "shift+enter=text:\\n"
            "super+enter=unbind"
            "super+d=unbind"
            # Ctrl+C remains as interrupt signal (default behavior)
            # Ghostty's default Ctrl+Shift+C/V already work for copy/paste
          ];

        macos-option-as-alt = "left";
        macos-secure-input-indication = true;
        auto-update = "download";
        auto-update-channel = "stable";
        macos-titlebar-style = "tabs";
        macos-icon = "blueprint";
        macos-icon-frame = "plastic";

        window-decoration = false;
        window-padding-x = 12;
        window-padding-y = 12;
        gtk-titlebar = false;

        window-height = 45;
        window-save-state = "always";
        window-new-tab-position = "end";
        window-subtitle = "working-directory";
        background-opacity =
          if isDarwin
          then 0.7
          else 1.0;
        background-blur-radius =
          if isDarwin
          then 50
          else 0;

        clipboard-read = "allow";
        clipboard-write = "allow";
        copy-on-select = false;
        clipboard-paste-protection = false;

        desktop-notifications = false;

        gtk-single-instance = true;
      };
    };
  };
}
