# ace — Mac (personal/dev): full mac workstation with embedded/jvm tooling.
{
  inputs,
  self,
  ...
}: {
  flake.darwinConfigurations.ace = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";

    modules = with self.modules.darwin; [
      macbook

      (
        {pkgs, ...}: {
          hostname = "ace";

          environment.variables = {
            OLLAMA_HOST = "192.168.2.5";
            OPENCODE_DISABLE_CLAUDE_CODE = "1";
            LIBRARY_PATH = "${pkgs.libiconv}/lib";
          };

          homebrew.casks = [
            "kicad"
          ];
        }
      )
    ];
  };
}
