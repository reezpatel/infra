{...}: let
  buildFunctions = {
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
    environment.systemPackages = [
      x
      dirsize
      extract
    ];
  };
in {
  moduleRegistry.darwin.shellFunctions = buildFunctions;
  moduleRegistry.nixos.shellFunctions = buildFunctions;
}
