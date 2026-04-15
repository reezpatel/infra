{inputs, ...}: let
  advancedPackagesModule = {pkgs, ...}: {
    environment.systemPackages = with pkgs;
      [
        postgresql.out
        go
        gcc
        kubectl
        nodejs_22
        yarn
        pnpm

        # firebase-tools
        python3
        uv
        nerd-fonts.jetbrains-mono

        nh
        ollama

        comma

        # glow # Markdown renderer for terminal
        # iftop # Network bandwidth monitor
        #
        #
        gitsign

        # LSP servers
        lua-language-server
        typescript-language-server
        vscode-langservers-extracted
        tailwindcss-language-server
        bash-language-server
        yaml-language-server

        # golang
        gopls
        golangci-lint
        gotools
        go-migrate
        delve

        # Formatters
        stylua
        prettierd
        prettier
        black
        gofumpt
        beautysh

        # Linters
        markdownlint-cli
        eslint_d

        # Tools
        ripgrep
        fzf
        lazygit
        delve

        # nix
        nil
        nixd
        alejandra
        nixfmt

        #terraform
        terraform-ls
        tflint
      ]
      ++ [inputs.agenix.packages.${pkgs.stdenv.system}.default];
  };
in {
  moduleRegistry.darwin.advancedPackages = advancedPackagesModule;
  moduleRegistry.nixos.advancedPackages = advancedPackagesModule;
}
