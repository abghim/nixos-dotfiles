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
			enable = false;
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
	networking.firewall.enable = false;
	networking.firewall.allowedTCPPorts = [ 8000 ];

	# Set your time zone.
	time.timeZone = "Asia/Seoul";

	hardware.graphics.enable = true;
	nixpkgs.config.allowUnfree = true;
	services.xserver.videoDrivers = [ "nvidia"];

	hardware.nvidia = {
		modesetting.enable = true;
		open = true;
		nvidiaSettings = true;
		package = config.boot.kernelPackages.nvidiaPackages.stable;
	};

	hardware.bluetooth = {
		enable = true;
		powerOnBoot = true;
		settings = {
			General = {
# Shows battery charge of connected devices on supported
# Bluetooth adapters. Defaults to 'false'.
				Experimental = true;
# When enabled other devices can connect faster to us, however
# the tradeoff is increased power consumption. Defaults to
# 'false'.
				FastConnectable = true;
			};
			Policy = {
# Enable all controllers when they are found. This includes
# adapters present on start as well as adapters that are plugged
# in later on. Defaults to 'true'.
				AutoEnable = true;
			};
		};
	};

	i18n.inputMethod = {
		enable = true;
		type = "fcitx5";

		fcitx5 = {
			waylandFrontend = true;
			addons = with pkgs; [ fcitx5-hangul fcitx5-gtk ];
		};
	};


	programs.hyprland = {
			enable = true;
			xwayland.enable = false;
	};
	
	services.blueman.enable = true;
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
	programs.localsend = {
		enable = true;
		openFirewall = true;
	};

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
		wl-clipboard
		awww
		ghostty
		vim 
		wget
		neovim
		tmux
		uv
		mesa-demos
		vulkan-tools
		pciutils

		# Korean
		kdePackages.fcitx5-configtool
		noto-fonts-cjk-sans
		noto-fonts-cjk-serif
	];

	environment.sessionVariables = {
		QT_IM_MODULE = "fcitx";
		QT_IM_MODULES = "wayland;fcitx;ibus";
	};

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
	programs.nix-ld.enable = true;

	system.stateVersion = "26.05"; # Never change this, no matter what
}

