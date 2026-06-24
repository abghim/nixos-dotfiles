# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
	imports = [
		./hardware-configuration.nix
	];

	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	boot.kernelPackages = pkgs.linuxPackages_latest;

	networking.hostName = "airden";

	networking.networkmanager.enable = true;

	# Set your time zone.
	time.timeZone = "Asia/Seoul";

	hardware.graphics.enable = true;
	programs.hyprland = {
			enable = true;
			xwayland.enable = true;
	};
	services.displayManager.ly.enable = true;
	services.displayManager.sddm = {
			enable = false; # true;
			wayland.enable = true;
	};
	xdg.portal = {
			enable = true;
			extraPortals = with pkgs; [
					xdg-desktop-portal-hyprland
							xdg-desktop-portal-gtk
			];
	};

	# Enable CUPS to print documents.
	services.printing.enable = true;

	# Enable sound.
	# services.pulseaudio.enable = true;
	# OR
	 services.pipewire = {
		 enable = true;
		 pulse.enable = true;
	 };

	programs.firefox.enable = true;
	programs.fish.enable = true;

	users.users.aiden = {
		isNormalUser = true;
		extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
		packages = with pkgs; [
			tree
		];
		shell = pkgs.fish;
	};

	environment.systemPackages = with pkgs; [
		git
		ghostty
		kitty
		vim 
		wget
		neovim
	];

	# Some programs need SUID wrappers, can be configured further or are
	# started in user sessions.
	programs.mtr.enable = true;
	programs.gnupg.agent = {
		enable = true;
		enableSSHSupport = true;
	};

	fonts.packages = with pkgs; [
		nerd-fonts.fira-code
	];

	# List services that you want to enable:

	# Enable the OpenSSH daemon.
	services.openssh.enable = true;
	nix.settings.experimental-features = [ "nix-command" "flakes" ];

	system.stateVersion = "26.05"; # Never change this, no matter what
}

