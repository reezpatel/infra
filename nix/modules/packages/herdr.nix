
{ inputs, ... }:
{
  flake.homeModules.herdr =
    { pkgs, ... }:
    {
      programs.herdr = {
        enable = true;
        settings = {
          keys = {
            prefix = "ctrl+x";

            split_vertical = [ "prefix+v" ];
            split_horizontal = [ "prefix+h" ];

            command = [
              {
                key = "prefix+alt+g";
                type = "overlay";
                command = "lazygit";
                description = "run lazygit";
                width = "80%";
                height = "80%";
              }
              {
                key = "prefix+t";
                type = "overlay";
                command = "exec \"${SHELL:-sh}\"";
                description = "open scratch terminal";
                width = "80%";
                height = "80%";
              }
              {
                key = "prefix+k";
                type = "plugin_action";
                command = "herdr-bar.open";
                description = "command bar";
              }
              {
                key = "prefix+o";
                type = "plugin_action";
                command = "herdr-zoxide.browse";
                description = "Browse zoxide directories";
              }
            ];
          }; 
        };
      };
    };
  }

