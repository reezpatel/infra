{...}: {
  flake.modules.homeManager.gemini = {pkgs, ...}: {
    home.packages = [
      pkgs.gemini-cli
    ];
  };
}
