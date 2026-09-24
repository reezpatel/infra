{ ... }: {
  flake.modules.nixos.kde_theme =
    { pkgs, ... }:
    let
      # materia-kde-theme ships only the legacy metadata.desktop format, which
      # Plasma 6 ignores - every KPackage component (look-and-feel packages and
      # desktop themes) needs a metadata.json, so generate one for each.
      # Aurorae/Kvantum/color-schemes are plain directory scans and don't need it.
      kpackageMetadata =
        structure: id: name:
        (pkgs.formats.json { }).generate "${id}-metadata.json" {
          KPackageStructure = structure;
          X-Plasma-API-Minimum-Version = "6.0";
          KPlugin = {
            Id = id;
            Name = name;
            Author = "Alexey Varfolomeev";
            Version = "20220823";
            License = "GPLv3";
            EnabledByDefault = true;
          };
        };

      lnfMetadata = kpackageMetadata "Plasma/LookAndFeel";
      themeMetadata = kpackageMetadata "Plasma/Theme";

      materia-kde = pkgs.runCommand "materia-kde" { } ''
        mkdir -p $out
        cp -r ${pkgs.materia-kde-theme}/share $out/share
        chmod -R u+w $out/share

        cp ${lnfMetadata "com.github.varlesh.materia" "Materia"} \
          $out/share/plasma/look-and-feel/com.github.varlesh.materia/metadata.json
        cp ${lnfMetadata "com.github.varlesh.materia-dark" "Materia Dark"} \
          $out/share/plasma/look-and-feel/com.github.varlesh.materia-dark/metadata.json
        cp ${lnfMetadata "com.github.varlesh.materia-light" "Materia Light"} \
          $out/share/plasma/look-and-feel/com.github.varlesh.materia-light/metadata.json
        cp ${themeMetadata "Materia" "Materia"} \
          $out/share/plasma/desktoptheme/Materia/metadata.json
        cp ${themeMetadata "Materia-Color" "Materia Color"} \
          $out/share/plasma/desktoptheme/Materia-Color/metadata.json
      '';
    in
    {
      environment.systemPackages = [
        materia-kde
        pkgs.papirus-icon-theme
        pkgs.material-cursors
      ];

      # Materia's look-and-feel styles Qt apps via Kvantum (MateriaDark theme).
      qt.style = "kvantum";
      environment.etc."xdg/Kvantum/kvantum.kvconfig".text = ''
        [General]
        theme=MateriaDark
      '';

      # System-wide default: use Materia as the Plasma (desktop) theme.
      # Users can still override this in ~/.config/plasmarc.
      environment.etc."xdg/plasmarc".text = ''
        [Theme]
        name=Materia
      '';
    };
}
