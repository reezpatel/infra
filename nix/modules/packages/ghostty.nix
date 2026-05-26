{...}: {
  flake.homeModules.ghostty = {
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
          pname = "ghostty-software-gl";
          inherit (pkgs.ghostty) version;

          dontUnpack = true;

          nativeBuildInputs = [
            pkgs.makeWrapper
          ];

          installPhase = ''
            runHook preInstall

            mkdir -p "$out/bin"
            makeWrapper ${lib.getExe pkgs.ghostty} "$out/bin/ghostty" \
              --set LIBGL_ALWAYS_SOFTWARE 1 \
              --set MESA_GL_VERSION_OVERRIDE 4.5 \
              --set MESA_GLSL_VERSION_OVERRIDE 450 \
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
        font-size = 14;
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

        keybind = [
          "shift+enter=text:\\n"
          "super+enter=unbind"
          "alt+left=unbind"
          "alt+right=unbind"
          "super+d=unbind"
        ];

        macos-option-as-alt = "left";
        macos-secure-input-indication = true;
        auto-update = "download";
        auto-update-channel = "stable";
        macos-titlebar-style = "tabs";
        macos-icon = "blueprint";
        macos-icon-frame = "plastic";

        window-height = 45;
        window-save-state = "always";
        window-new-tab-position = "end";
        window-subtitle = "working-directory";
        background-opacity = 0.7;
        background-blur-radius = 50;

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
