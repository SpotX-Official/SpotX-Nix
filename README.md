# SpotX-Nix

Declarative Nix packaging for [SpotX-Bash](https://github.com/SpotX-Official/SpotX-Bash).

SpotX-Nix patches Spotify while its Nix derivation is being built. It does not modify an existing package in `/nix/store`.

## NixOS with flakes

Add SpotX-Nix to your flake inputs:

```nix
inputs.spotx-nix = {
  url = "github:SpotX-Official/SpotX-Nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add its overlay and package to your NixOS configuration:

```nix
{
  nixpkgs = {
    config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "spotify"
        "spotify-spotx"
      ];
    overlays = [ inputs.spotx-nix.overlays.default ];
  };

  environment.systemPackages = [ pkgs.spotify-spotx ];
}
```

For Home Manager, use the same overlay and add `pkgs.spotify-spotx` to `home.packages`.

## SpotX-Bash options

Customize the package by passing regular SpotX-Bash arguments:

```nix
environment.systemPackages = [
  (pkgs.spotify-spotx.override {
    spotxArgs = [
      "--premium"
      "--hide"
    ];
  })
];
```

Do not enable interactive or client-installation options during a Nix build.

## Updates

An automated workflow checks for new SpotX-Bash and Nixpkgs revisions every six hours. It updates the locked inputs only when:

1. The latest SpotX-Bash supported version is equal to or newer than Nixpkgs' Spotify version.
2. The patched Spotify derivation builds successfully.

If Nixpkgs provides a newer Spotify version than SpotX-Bash supports, no repository changes are made. The scheduled workflow checks again six hours later.
