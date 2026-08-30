{...}: {
  # Feature: devops (homeManager) — database/infra CLIs used during
  # development: postgres client, kubernetes, migrations, commit signing.
  flake.modules.homeManager.devops = {pkgs, ...}: {
    home.packages = with pkgs; [
      postgresql.out # psql client
      kubectl
      go-migrate
      gitsign
    ];
  };
}
