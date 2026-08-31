{...}: {
	flake.modules.nixos.gui_base = {...}: {
		environment.sessionVariables.NIXOS_OZONE_WL = "1";
	};

	xdg = {
	  portal = {
	    enable = true;
	    extraPortals = with pkgs; [
	      xdg-desktop-portal-wlr
	      xdg-desktop-portal-gtk
	    ];
	  };
	};
}
