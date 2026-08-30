{
  self,
  inputs,
  ...
}: {
  flake.modules.homeManager.shell.imports = with self.modules.homeManager;
    [
      zsh
      zoxide
      fastfetch
      git
      tmux
      vim
    ]
    ++ [
      inputs.agenix.homeManagerModules.default
    ];
}
