{ inputs, config, pkgs, ... }:

let
dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;

configs = {
	fish = "fish";
	ghostty = "ghostty";
	hypr = "hypr";
	eza = "eza";
	quickshell = "quickshell";
	nvim = "nvim";
	alacritty = "alacritty";
};

in
{
	home.username = "aiden";
	home.homeDirectory = "/home/aiden";
	programs.git = {
		enable = true;
		userName = "Aiden Ghim";
		userEmail = "aiden.bj.ghim@gmail.com";
		extraConfig = {
			credential.helper = "store";
			init.defaultBranch = "master";
			pull.rebase = true;
		};
	};
	home.stateVersion = "25.05";
	programs.bash = {
		enable = true;
		shellAliases = {
			btw = "echo i use nixos, btw";
		};
	};

	home.pointerCursor = {
		package = pkgs.bibata-cursors;
		name = "Bibata-Modern-Classic";
		size = 30;

		gtk.enable = true;
		x11.enable = true;
	};

	gtk = {
		enable = true;
		iconTheme = {
			name = "Adwaita";
			package = pkgs.adwaita-icon-theme;
		};
	};

	services.swaync = {
		enable = true;
		style = ./config/swaync/swaync-style.css;
		settings = {
			positionX = "right";
			positionY = "top";
			control-center-width = 510;
			notification-window-width = 510;
			notification-grouping = true;
			widgets = ["mpris" "notifications" "menubar#footer"];
			text-empty = "";
			image-visibility = "when-available";
			widget-config = {
				"menubar#footer" = {
					"buttons#footer-actions" = {
						position = "right";
						actions = [
							{
								label = "Clear All Notifications";
								command = "swaync-client --close-all";
							}
							{
								label = "Do Not Disturb";
								type = "toggle";
								command = "if [ \"$SWAYNC_TOGGLE_STATE\" = true ]; then swaync-client --dnd-on; else swaync-client --dnd-off; fi";
								update-command = "swaync-client --get-dnd";
							}
						];
					};
				};
				mpris = {
					show-album-art = "when-available";
					autohide = true;
				};
			};

			layer = "overlay";
			control-center-layer = "top";
			notification-2fa-action = true; notification-inline-replies = true;
			timeout = 7; timeout-low = 3; timeout-critical = 0;
		};
	};

	systemd.user.services.wallpaper = {
		Unit.Description = "Rocky wallpaper";
		Service = {
			Type = "oneshot";
			ExecStart = "/home/aiden/nixos-dotfiles/packages/rocky-day/result/bin/rocky";
		};
	};

	systemd.user.timers.wallpaper = {
		Unit.Description = "Rocky wallpaper timer";
		Timer = {
			OnStartupSec = "10s";
			OnUnitInactiveSec = "10s";
			AccuracySec = "1s";
			Unit = "wallpaper.service";
		};
		Install.WantedBy = [ "timers.target"];
	};

# dotfile symlinking
	xdg.configFile = builtins.mapAttrs (name: subpath: {
			source = create_symlink "${dotfiles}/${subpath}";
			recursive = true;
			}) configs;


	home.file.".tmux" = {
		source = create_symlink "${dotfiles}/tmux/.tmux";
		recursive = true;
	};
	home.file.".tmux.conf".source = create_symlink "${dotfiles}/tmux/.tmux.conf";

# fonts
	home.file.".local/share/fonts/MonacoLigaturizedNerdFont".source = ./config/fonts/MonacoLigaturizedNerdFont;
	home.file.".local/share/fonts/AppleColorEmoji.ttf".source = ./config/fonts/AppleColorEmoji-Linux.ttf;
	home.file.".local/share/fonts/Helvetica".source = ./config/fonts/Helvetica;

	home.packages = with pkgs; [
		neovim tree-sitter
		libnotify
			ripgrep
			nil lua-language-server qt6.qtdeclarative
			nixpkgs-fmt
			nodejs btop
			gcc
			eza
			quickshell
			coreutils
			gnumake
			rustup
			zoxide
			fortune
			lolcat
			fastfetch
			thunar
			alacritty thunderbird
			opencode
			bun
			slack
			gum
			zip unzip
			docker docker-compose
			vicinae
			] ++ [
# inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
			(pkgs.writeShellScriptBin "zen" ''
			 exec flatpak run app.zen_browser.zen "$@"
			 '')
			] ++ [
				inputs.sidra.packages.${pkgs.stdenv.hostPlatform.system}.default
			];
}
