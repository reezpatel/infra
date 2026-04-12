{...}: {
  flake.homeModules.autojump = {...}: {
    programs.autojump = {
      enable = true;
    };
  };
}
