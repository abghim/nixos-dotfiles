{
	description = "abghim's nixos setup";

	inputs = {
		nixpkgs.url = "nixpkgs/nixos-unstable";
		home-manager = {
			url = "github:nix-community/home-manager/master";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		zen-browser = {
			url = "github:youwen5/zen-browser-flake";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = inputs@{ self, nixpkgs, home-manager, ... }: {
		nixosConfigurations.airden = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				./configuration.nix
				home-manager.nixosModules.home-manager
				{
					home-manager = {
						extraSpecialArgs = {
							inherit inputs;
						};
						useGlobalPkgs = true;
						useUserPackages = true;
						users.aiden = import ./home.nix;
						backupFileExtension = "bak";
					};
				}
			];
		};
	};
}
