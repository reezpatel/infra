{ lib, pkgs, ... }:
{
  environment.shellAliases = {
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

    # Others
    cat = "bat";

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

    # Tmux sessions
    # conductly = "tmux -S /run/user/1000/tmux-conductly attach -t conductly";
    # river = "tmux -S /run/user/1000/tmux-river attach -t river";
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    open = "xdg-open";
    rxp = "/home/dustin/.local/share/src/restxp/restxp";
    windows = "sudo systemctl reboot --boot-loader-entry=auto-windows";
  };
}
