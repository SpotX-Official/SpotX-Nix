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
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      eachSystem = nixpkgs.lib.genAttrs systems;
      pkgs = eachSystem (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfreePredicate =
            pkg:
            builtins.elem (nixpkgs.lib.getName pkg) [
              "spotify"
              "spotify-spotx"
            ];
          overlays = [ self.overlays.default ];
        }
      );
    in
    {
      overlays.default = final: prev: {
        spotify-spotx = final.callPackage ./nix/package.nix {
          inherit (final.darwin) DarwinTools sigtool system_cmds;
          spotxSource = spotx-bash;
        };
      };

      packages = eachSystem (system: {
        inherit (pkgs.${system}) spotify-spotx;
        default = pkgs.${system}.spotify-spotx;
      });

      checks = eachSystem (system: {
        default = pkgs.${system}.spotify-spotx;
      });
    };
}
