{...}: {
  # Feature: runtimes (homeManager) — language runtimes and toolchains.
  #
  # Moved out of the system-wide advanced-packages set into the user's home
  # profile: only the primary user develops; system services bring their own
  # dependencies. Stays out of the editor modules on purpose — runtimes are
  # useful without an editor (scripts, CI, one-off commands).
  flake.modules.homeManager.runtimes = {pkgs, ...}: {
    home.packages = with pkgs; [
      go
      gcc
      nodejs_22
      yarn
      pnpm
      python3
      uv

      openjdk

      rustc
      cargo
    ];

    environment.systemPackages = with pkgs; [
      # igraph
      # clang-tools
      # arduino-cli
      # docker-compose
    ];
  };
}
