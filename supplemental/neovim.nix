{inputs, ...}: {
  flake.nixosModules.neovim = {
    home-manager.users.matthew.imports = [
      {
        imports = [inputs.nvf.homeManagerModules.default];

        home.sessionVariables = {
          MANPAGER = "nvim +Man!";
        };

        programs.neovim = {
          enable = true;
          defaultEditor = true;
        };

        programs.nvf = {
          enable = true;
          settings = {
            vim = {
              luaConfigPost = ''
                vim.opt.shiftwidth = 2
                -- vim.opt.colorcolumn = "80"
              '';
              treesitter.indent.enable = false;

              lsp = {
                enable = true;
                lspconfig.enable = true;
                mappings.format = "<C-F>";
              };

              languages = {
                enableFormat = true;
                enableTreesitter = true;

                nix.enable = true;
                markdown.enable = true;
                bash.enable = true;
                lua.enable = true;
                css.enable = true;

                csharp = {
                  enable = true;
                  lsp = {
                    enable = true;
                    servers = ["roslyn_ls"];
                  };
                  treesitter.enable = true;
                };
              };

              visuals = {
                nvim-cursorline.enable = true;
              };

              theme = {
                enable = true;
                name = "gruvbox";
                style = "dark";
              };

              statusline = {
                lualine.enable = true;
              };

              autopairs = {
                nvim-autopairs.enable = true;
              };

              autocomplete = {
                nvim-cmp.enable = true;
              };

              filetree = {
                neo-tree.enable = true;
              };

              tabline = {
                nvimBufferline = {
                  enable = true;
                  mappings = {
                    closeCurrent = "<leader>x";
                    cycleNext = "<S-l>";
                    cyclePrevious = "<S-h>";
                    moveNext = "<leader>l";
                    movePrevious = "<leader>h";
                  };
                };
              };

              telescope.enable = true;

              git = {
                enable = true;
              };

              utility = {
                ccc.enable = true;
              };

              notes = {
                todo-comments.enable = true;
              };

              ui = {
                fastaction.enable = true; # Not so sure about it.
              };

              keymaps = [
                {
                  mode = [
                    "n"
                    "v"
                    "i"
                  ];
                  key = "<C-n>";
                  action = "<cmd>Neotree toggle left<CR>";
                }

                {
                  mode = "n";
                  key = "<C-h>";
                  action = "<C-w>h";
                }
                {
                  mode = "n";
                  key = "<C-j>";
                  action = "<C-w>j";
                }
                {
                  mode = "n";
                  key = "<C-k>";
                  action = "<C-w>k";
                }
                {
                  mode = "n";
                  key = "<C-l>";
                  action = "<C-w>l";
                }
              ];
            };
          };
        };
      }
    ];
  };
}
