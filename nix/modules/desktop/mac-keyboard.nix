{...}: {
  flake.modules.nixos.mac-keyboard = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.macKeyboard = {
      enable = lib.mkEnableOption "Mac keyboard remapping for Wayland";
    };

    config = lib.mkIf config.macKeyboard.enable {
      # Configure hid_apple kernel module for Mac keyboards
      # fnmode=1: Media keys by default, Fn+key for F1-F12
      boot.extraModprobeConfig = ''
        options hid_apple fnmode=1
      '';

      # xremap needs evdev input access and uinput output access.
      users.users.${config.username}.extraGroups = ["input" "uinput"];
      hardware.uinput.enable = true;
      boot.kernelModules = ["uinput"];
      services.udev.extraRules = ''
        KERNEL=="uinput", GROUP="uinput", TAG+="uaccess", MODE:="0660", OPTIONS+="static_node=uinput"
      '';

      # Configure home-manager for the user
      home-manager.users.${config.username} = {
        xdg.configFile."xremap/config.yml".text = ''
          virtual_modifiers:
            - CapsLock

          keymap:
            - name: Niri CapsLock modifier
              remap:
                CapsLock-left: C-A-Super-left
                CapsLock-right: C-A-Super-right
                CapsLock-up: C-A-Super-up
                CapsLock-down: C-A-Super-down
                CapsLock-Shift-left: C-A-Super-Shift-left
                CapsLock-Shift-right: C-A-Super-Shift-right
                CapsLock-Shift-up: C-A-Super-Shift-up
                CapsLock-Shift-down: C-A-Super-Shift-down
                CapsLock-f: C-A-Super-f
                CapsLock-t: C-A-Super-t
                CapsLock-r: C-A-Super-r
                CapsLock-Shift-r: C-A-Super-Shift-r
                CapsLock-c: C-A-Super-c
                CapsLock-e: C-A-Super-e
                CapsLock-pageup: C-A-Super-pageup
                CapsLock-pagedown: C-A-Super-pagedown
                CapsLock-Shift-pageup: C-A-Super-Shift-pageup
                CapsLock-Shift-pagedown: C-A-Super-Shift-pagedown
                CapsLock-space: C-A-Super-space
                CapsLock-Enter: C-A-Super-Enter

            - name: Ghostty
              application:
                only:
                  - ghostty
                  - com.mitchellh.ghostty
                  - /.*[Gg]hostty.*/
              remap:
                Super-c: C-Shift-c
                Super-v: C-Shift-v
                Super-Shift-t: C-Shift-t
                Super-left: C-a
                Super-right: C-e
                Super-backspace: [C-a, C-k]
                Alt-left: Alt-b
                Alt-right: Alt-f
                Alt-backspace: C-w
                # Mac-style mouse clicks
                Super-BTN_LEFT: C-BTN_LEFT
                Super-BTN_RIGHT: C-BTN_RIGHT
                Super-BTN_MIDDLE: C-BTN_MIDDLE

            - name: Global Mac shortcuts
              application:
                not:
                  - ghostty
                  - com.mitchellh.ghostty
                  - /.*[Gg]hostty.*/
              remap:
                Super-c: C-c
                Super-v: C-v
                Super-x: C-x
                Super-z: C-z
                Super-a: C-a
                Super-s: C-s
                Super-n: C-n
                Super-Shift-t: C-Shift-t
                Super-left: Home
                Super-right: End
                Super-backspace: [Home, Shift-End, Backspace]
                Alt-left: C-left
                Alt-right: C-right
                Alt-backspace: C-backspace
                # Mac-style mouse clicks (Cmd+click → Ctrl+click)
                Super-BTN_LEFT: C-BTN_LEFT
                Super-BTN_RIGHT: C-BTN_RIGHT
                Super-BTN_MIDDLE: C-BTN_MIDDLE
        '';

        systemd.user.services.xremap = {
          Unit = {
            Description = "xremap Niri-aware Mac keyboard remapping";
            After = ["graphical-session.target"];
          };
          Service = {
            ExecStart = "${pkgs.xremap.niri}/bin/xremap --watch=config,device --output-device-name xremap-mac-keyboard %h/.config/xremap/config.yml";
            Restart = "always";
            RestartSec = 3;
            Type = "simple";
          };
          Install = {
            WantedBy = ["graphical-session.target"];
          };
        };
      };

      # Mark the xremap virtual keyboard as internal for compositor/input handling.
      environment.etc."libinput/local-overrides.quirks".text = ''
        [xremap Keyboard]
        MatchUdevType=keyboard
        MatchName=xremap-mac-keyboard
        AttrKeyboardIntegration=internal
      '';
    };
  };
}
