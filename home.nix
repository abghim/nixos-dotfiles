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
		tmux_helpers = "tmux_helpers";
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
        neovim
        ripgrep
        nil
        nixpkgs-fmt
        nodejs
        gcc
        wofi
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
		alacritty
		gum
		zip unzip
    ] ++ [
		# inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
		(pkgs.writeShellScriptBin "zen" ''
			exec flatpak run app.zen_browser.zen "$@"
		'')
	];
}
