{...}: {
  flake.homeModules.git = {pkgs, ...}: let
    isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  in {
    programs.git = {
      enable = true;

      settings = {
        user = {
          name = "Reez";
          email = "reezpatel@gmail.com";
        };

        core = {
          editor = "nvim";
          autocrlf = "input";
          whitespace = "trailing-space,space-before-tab";
        };

        init.defaultBranch = "main";

        color = {
          ui = true;
          diff = {
            meta = "bold";
            frag = "bold";
            commit = "bold";
            old = "red";
            new = "blue";
            whitespace = "yellow reverse";
          };
          status = {
            added = "blue";
            changed = "red";
            untracked = "yellow";
          };
        };

        pull.rebase = false;

        push = {
          default = "simple";
          autoSetupRemote = true;
          followTags = true;
        };

        merge = {
          ff = "only";
          tool = "vimdiff";
          conflictstyle = "diff3";
        };

        diff = {
          tool = "vimdiff";
          colorMoved = "default";
        };

        "branch \"main\"".rebase = true;

        status.showUntrackedFiles = "all";

        help.autocorrect = 1;

        credential.helper =
          if isDarwin
          then "osxkeychain"
          else "cache --timeout=3600";

        # alias = {
        #   co = "checkout";
        #   ci = "commit";
        #   di = "diff";
        #   gr = "grep";
        #   mg = "merge";
        #   rb = "rebase";
        #   br = "branch --all --verbose --verbose";
        #   st = "status --short --branch";
        #   lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %C(green)(%cr) %C(blue)<%an>%Creset'";

        #   # rebasing
        #   rbi = "rebase --interactive @{upstream}";
        #   rbc = "rebase --continue";
        #   rbs = "rebase --skip";
        #   rba = "rebase --abort";

        #   # release/unrelease
        #   release = "!f(){ git tag $1 && git push --tags; };f";
        #   unrelease = "!f(){ git tag -d $1 && git push origin \\\":$1\\\"; };f";

        #   # publish/unpublish branch
        #   branch-name = "!git rev-parse --abbrev-ref HEAD";
        #   publish = "!git push -u origin $(git branch-name)";
        #   unpublish = "!git push origin :$(git branch-name)";

        #   upload = "!git push && git push --tags";

        #   # stash
        #   wip = "stash push -a";
        #   unwip = "stash pop";
        #   snapshot = "!git stash push -a -m \"snapshot: $(date)\" && git stash apply stash@{0}";

        #   # index
        #   stage = "add --all";
        #   unstage = "reset HEAD";

        #   # working-copy
        #   revert = "checkout --force";
        #   revert-all = "reset --hard HEAD";

        #   # commits
        #   extend = "commit --amend --no-edit -a";
        #   amend = "commit --amend";
        #   undo = "reset --soft HEAD^";
        #   undo-hard = "reset --hard HEAD^";

        #   # assume unchanged
        #   assumed = "!git ls-files -v | grep ^h | cut -c 3-";
        #   assume = "update-index --assume-unchanged";
        #   unassume = "update-index --no-assume-unchanged";

        #   # optimize
        #   optimize-prune = "!git prune --expire=now && git reflog expire --expire-unreachable=now --rewrite --all";
        #   optimize-repack = "repack -a -d -f --depth=300 --window=300 --window-memory=1g";
        #   optimize = "!git optimize-prune && git optimize-repack";

        #   # misc
        #   branches-prune = "!git branch --no-color --merged master | grep -v \"\\\\* master\" | grep -v \"\\\\*\" | xargs -n 1 git branch -d";
        #   branches = "branch -a";
        #   tags = "tag -n1 --list";
        #   stashes = "stash list";
        #   new = "checkout -b";
        #   del = "reset HEAD";
        # };
      };

      lfs.enable = true;
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
        pager = "${pkgs.less}/bin/less --mouse --wheel-lines=3";
      };
    };

    programs.lazygit = {
      enable = true;
      settings = {
        # This looks better with the kitty theme.
        gui.theme = {
          lightTheme = false;
          activeBorderColor = ["white" "bold"];
          inactiveBorderColor = ["white"];
          selectedLineBgColor = ["reverse" "white"];
        };
      };
    };

    programs.mergiraf = {
      enable = true;
      enableGitIntegration = true;
      enableJujutsuIntegration = true;
    };
  };
}
