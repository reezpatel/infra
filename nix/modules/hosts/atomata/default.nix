# atomata — Mac (main access portal): full mac workstation, same shape as
# ace. This is the primary jump/access machine: its user key is in the
# global authorizedKeys (features/common/core.nix) and its host key is in
# the agenix `all` array (secerts/secrets.nix).
{
  inputs,
  self,
  ...
}: {
  flake.darwinConfigurations.atomata = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";

    modules = with self.modules.darwin; [
      macbook
      twodb-runner

      (
        { ... }: {
          hostname = "atomata";

          environment.variables = {
            OLLAMA_HOST = "192.168.2.5";
            OPENCODE_DISABLE_CLAUDE_CODE = "1";
          };

          # Host-specific casks go here (ace has deskflow/kicad for
          # embedded work — omitted on atomata, which is an access portal).
          homebrew.casks = [];
        }
      )
    ];
  };
}
