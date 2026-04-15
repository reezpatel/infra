{...}: {
  flake.homeModules.zsh = {
    lib,
    pkgs,
    config,
    ...
  }: {
    programs.carapace = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      completionInit = "autoload -U compinit && compinit -u";
      autosuggestion.enable = true;
      syntaxHighlighting = {
        enable = true;
        highlighters = [
          "main"
          "brackets"
          "pattern"
          "regexp"
          "cursor"
          "line"
        ];
      };

      # antidote = {
      #   enable = true;
      #   plugins = [
      #     "zsh-users/zsh-autosuggestions"
      #     "zsh-users/zsh-syntax-highlighting"
      #   ];
      # };

      initContent =
        ''
          SPACESHIP_PROMPT_ASYNC=false
          source ${pkgs.spaceship-prompt}/lib/spaceship-prompt/spaceship.zsh
          source ${pkgs.autoenv}/share/autoenv/activate.sh
        ''
        + lib.optionalString (lib.hasAttrByPath ["age" "secrets" "private-func"] config) ''
          [[ -f ${config.age.secrets.private-func.path} ]] && source ${config.age.secrets.private-func.path}
        ''
        + ''


          if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
            . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
          fi

          bindkey '^[^M' autosuggest-execute
          zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

          export TERM=xterm-256color

          # PATH
          export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
          export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
          export PATH=$HOME/.local/share/bin:$PATH
          export PYTHONPATH="$HOME/.local-pip/packages:$PYTHONPATH"

          export HISTIGNORE="pwd:ls:cd"

          export VISUAL="zed"
          if command -v nvim &>/dev/null; then
            export EDITOR="nvim"
          else
            export EDITOR="vim"
          fi

          eval "$(git wt --init zsh)"
        '';
    };
  };
}
