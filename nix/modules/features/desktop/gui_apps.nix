{...}: {
	environment.systemPackages = with pkgs; [
		slack
		karere
		discord
		telegram-desktop
		kicad
	];
}
