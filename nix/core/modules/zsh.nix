{
  pkgs,
  config,
  ...
}: let
  user = config.core.username;
in {
  home-manager.users.${user}.programs.zsh = {
    enable = true;
    enableCompletion = true;

    antidote = {
      enable = true;
      plugins = [
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-syntax-highlighting"
      ];
    };

    initContent = ''
      SPACESHIP_PROMPT_ASYNC=false
      source ${pkgs.spaceship-prompt}/lib/spaceship-prompt/spaceship.zsh
      source ${pkgs.autoenv}/share/autoenv/activate.sh

      # TODO: Remove these two
      if [[ -f $HOME/.config/dotfiles/saaf-func.sh ]]; then
        source $HOME/.config/dotfiles/saaf-func.sh
        saaf-dev
      fi

      if [[ -f $HOME/.config/dotfiles/shell_functions.sh ]]; then
        source $HOME/.config/dotfiles/shell_functions.sh
      fi

      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

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
}
