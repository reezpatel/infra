{...}: let
  # Shell environment shared by NixOS and nix-darwin hosts: system-wide
  # aliases plus small helper utilities (x, dirsize, extract).
  shellModule = {
    lib,
    pkgs,
    ...
  }: let
    x = pkgs.writeShellApplication {
      name = "x";
      text = ''
        if [ "$#" -lt 2 ]; then
          echo "Usage: x <number_of_times> <command>" >&2
          exit 1
        fi

        count="$1"
        shift

        i=1
        while [ "$i" -le "$count" ]; do
          "$@"
          i=$((i + 1))
        done
      '';
    };

    dirsize = pkgs.writeShellApplication {
      name = "dirsize";
      runtimeInputs = [pkgs.coreutils];
      text = ''
        du -sh "$1"
      '';
    };

    extract = pkgs.writeShellApplication {
      name = "extract";
      runtimeInputs = [
        pkgs.gnutar
        pkgs.gzip
        pkgs.bzip2
        pkgs.unzip
        pkgs.p7zip
        pkgs.unrar
        pkgs.ncompress
      ];
      text = ''
        if [ ! -f "$1" ]; then
          echo "'$1' is not a valid file" >&2
          exit 1
        fi

        case "$1" in
          *.tar.bz2) tar xvjf "$1" ;;
          *.tar.gz) tar xvzf "$1" ;;
          *.bz2) bunzip2 "$1" ;;
          *.rar) unrar x "$1" ;;
          *.gz) gunzip "$1" ;;
          *.tar) tar xvf "$1" ;;
          *.tbz2) tar xvjf "$1" ;;
          *.tgz) tar xvzf "$1" ;;
          *.zip) unzip "$1" ;;
          *.Z) uncompress "$1" ;;
          *.7z) 7z x "$1" ;;
          *) echo "don't know how to extract '$1'" >&2; exit 1 ;;
        esac
      '';
    };
  in {
    environment.shellAliases =
      {
        # Better ls
        ls = "eza --color --grid -F --hyperlink --group-directories-first -l --no-filesize -m --no-permissions --no-user --no-time";
        ll = "eza -1 --color -F --hyperlink --group-directories-first -l --no-filesize -m --no-permissions --group -o --icons --git";

        # Random
        rand = "openssl rand -hex";
        uuid = ''uuidgen | tr "[:upper:]" "[:lower:]"'';

        # Movement
        ".." = "cd ..";
        "..." = "cd ../..";

        # Untar
        untar = "tar -zxvf $1";

        # AWS Vault
        av = "aws-vault";

        # File Management
        rm = "rm -i";
        cp = "cp -i";
        mv = "mv -i";
        trash = "mv -t ~/.Trash/";

        # Updates
        update = "sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; npm install npm -g; npm update -g; sudo gem update --system; sudo gem update; sudo gem cleanup";

        # Git
        g = "git";
        ga = "git add";
        gs = "git status";
        gc = "git commit";
        gaa = "git add -A";
        gcm = "git checkout main";
        gfm = "git fetch origin main";
        gmm = "git merge origin/main";
        gpm = "git pull origin main -r";
        gpo = "git push origin $(git rev-parse --abbrev-ref HEAD)";
        gmc = "git merge --continue";
        gcp = "git cherry-pick";
        gcpc = "git cherry-pick --continue";
        glog = ''git log --graph --abbrev-commit --decorate --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)" --all'';

        # Terraform
        tf = "terraform";
        tfp = "terraform plan";
        tfi = "terraform init -upgrade";

        # Misc
        n = "nvim";
        c = "clear";
        tadd = "tmux new -A -s";

        # Search
        search = ''rg -p --glob "!node_modules/*" --glob "!vendor/*" "$@"'';

        # Difftastic
        diff = "difft";
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        open = "xdg-open";
        rxp = "/home/dustin/.local/share/src/restxp/restxp";
        windows = "sudo systemctl reboot --boot-loader-entry=auto-windows";
      };

    environment.systemPackages = [
      x
      dirsize
      extract
    ];
  };
in {
  flake.modules.nixos.environment = shellModule;
  flake.modules.darwin.environment = shellModule;
}
