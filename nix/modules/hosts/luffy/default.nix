# luffy — MacBook Pro (work): full mac workstation with autossh DB tunnels.
{
  inputs,
  self,
  ...
}: {
  flake.darwinConfigurations.luffy = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";

    modules = with self.modules.darwin; [
      macbook

      ./_auto-ssh.nix

      (
        {
          config,
          pkgs,
          ...
        }: {
          hostname = "luffy";

          environment.variables = {
            OLLAMA_HOST = "192.168.2.5";
            OPENCODE_DISABLE_CLAUDE_CODE = "1";
          };

          environment.systemPackages = with pkgs; [
            codecov-cli
          ];

          home-manager.users.${config.username} = {...}: {
            age.identityPaths = ["/Users/reezpatel/.ssh/id_ed25519"];
            age.secrets.private-func.file = ../../../../secerts/private-func.age;
          };

          homebrew.casks = [
            "1password"
            "postman"
          ];
        }
      )
    ];
  };
}
