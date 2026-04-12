{...}: {
  moduleRegistry.darwin.macosConfig = {config, ...}: {
    time.timeZone = "Asia/Calcutta";

    networking.computerName = config.hostname;

    launchd.user.agents.tmux-tmpdir = {
      script = ''
        mkdir -p /Users/${config.username}/.local/share/tmux
        chmod 700 /Users/${config.username}/.local/share/tmux
      '';
      serviceConfig = {
        RunAtLoad = true;
        Label = "dev.${config.username}.tmux-tmpdir";
      };
    };

    system = {
      # Turn off NIX_PATH warnings now that we're using flakes
      checks.verifyNixPath = false;

      primaryUser = config.username;

      stateVersion = 6;

      defaults = {
        LaunchServices = {
          LSQuarantine = false;
        };
        NSGlobalDomain = {
          AppleInterfaceStyle = "Dark";
          AppleShowAllExtensions = true;
          ApplePressAndHoldEnabled = false;
          AppleEnableSwipeNavigateWithScrolls = false;
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticSpellingCorrectionEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = true;
          "com.apple.swipescrolldirection" = false;

          # 120, 90, 60, 30, 12, 6, 2
          KeyRepeat = 2;

          # 120, 94, 68, 35, 25, 15
          InitialKeyRepeat = 15;
          "com.apple.mouse.tapBehavior" = 1;
          "com.apple.sound.beep.volume" = 0.0;
          "com.apple.sound.beep.feedback" = 0;
        };
        dock = {
          autohide = true;
          autohide-delay = 0.0;
          autohide-time-modifier = 0.0;
          orientation = "left";
          tilesize = 46;
          show-recents = false;
          launchanim = false;
          mineffect = "scale";
          expose-animation-duration = 0.1;
        };
        finder = {
          _FXShowPosixPathInTitle = false;
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          FXPreferredViewStyle = "Nlsv";
        };
        trackpad = {
          Clicking = true;
          TrackpadThreeFingerDrag = true;
        };
        ".GlobalPreferences"."com.apple.mouse.scaling" = 2.0;
      };
    };
  };
}
