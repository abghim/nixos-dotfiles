{ config, pkgs, ... }:

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

    xdg.configFile = builtins.mapAttrs (name: subpath: {
            source = create_symlink "${dotfiles}/${subpath}";
            recursive = true;
    }) configs;

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
    ];
}
