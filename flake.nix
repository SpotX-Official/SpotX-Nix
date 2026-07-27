{
  description = "Declarative Nix package for SpotX-Bash";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    spotx-bash = {
      url = "github:SpotX-Official/SpotX-Bash";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      spotx-bash,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "spotify"
            "spotify-spotx"
          ];
        overlays = [ self.overlays.default ];
      };
    in
    {
      overlays.default = final: prev: {
        spotify-spotx = final.callPackage ./nix/package.nix {
          spotxSource = spotx-bash;
        };
      };

      packages.${system} = {
        inherit (pkgs) spotify-spotx;
        default = pkgs.spotify-spotx;
      };

      checks.${system}.default = pkgs.spotify-spotx;
    };
}
