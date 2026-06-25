# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
	imports = [
		./hardware-configuration.nix
	];


	boot = {
		loader = {
			systemd-boot.enable = true;
			efi.canTouchEfiVariables = true;
		};
		kernelPackages = pkgs.linuxPackages_latest;

		plymouth = {
			enable = true;
			theme = "blahaj";
			themePackages = [
				pkgs.plymouth-blahaj-theme
			];
		};

		consoleLogLevel = 0;
		initrd.verbose = false;

		kernelParams = [
			"quiet"
			"splash"
			"udev.log_level=3"
		];
	};

	networking.hostName = "airden";
	networking.networkmanager.enable = true;

	# Set your time zone.
	time.timeZone = "Asia/Seoul";

	hardware.graphics.enable = true;
	programs.hyprland = {
			enable = true;
			xwayland.enable = false;
	};
	


	services.xserver.enable = false;
	services.displayManager.ly.enable = true;
	services.displayManager.sddm = {
		enable = false; # true;
		wayland.enable = false;
	};

	security.polkit.enable = true;

	xdg.portal = {
		enable = true;
		extraPortals = with pkgs; [
			xdg-desktop-portal-gtk
		];
	};

# Enable CUPS to print documents.
	services.printing.enable = true;
	services.flatpak.enable = true;

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
		hyprpaper
		ghostty
		vim 
		wget
		neovim
		tmux
	];

# Some programs need SUID wrappers, can be configured further or are
# started in user sessions.
	programs.mtr.enable = true;
	programs.gnupg.agent = {
		enable = true;
		enableSSHSupport = true;
	};

	fonts = {
		packages = with pkgs; [
			nerd-fonts.fira-code
		];

		fontconfig = {
			enable = true;
			defaultFonts = {
				serif = ["Helvetica"];
				sansSerif = ["Helvetica"];
				monospace = ["MonacoLigaturized Nerd Font"];
				emoji = ["Apple Color Emoji"];
			};
		};
	};

# List services that you want to enable:

# Enable the OpenSSH daemon.
	services.openssh.enable = true;
	nix.settings.experimental-features = [ "nix-command" "flakes" ];

	system.stateVersion = "26.05"; # Never change this, no matter what
}

