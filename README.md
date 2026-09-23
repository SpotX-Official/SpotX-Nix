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

## NixOS without flakes

Two variants — pick one. Both are imported the same way from `configuration.nix`:

```nix
{
  imports = [ ./modules/spotify-spotx.nix ];
}
```

### Variant A — impure, zero maintenance

> [!WARNING]
> **Not reproducible.** This variant uses `builtins.fetchGit`, which has no hash argument, so it follows upstream `main` instead of a pinned revision. A rebuild can pull in an unreviewed upstream commit.

```nix
# modules/spotify-spotx.nix
{ config, pkgs, lib, ... }:
let
  spotxNix = builtins.fetchGit {
    url = "https://github.com/SpotX-Official/SpotX-Nix";
    ref = "refs/heads/main";
  };

  spotxBash = builtins.fetchGit {
    url = "https://github.com/SpotX-Official/SpotX-Bash";
    ref = "refs/heads/main";
  };

  spotify-spotx = pkgs.callPackage "${spotxNix}/nix/package.nix" {
    spotxSource = spotxBash;
    # spotxArgs = [ "--premium" "--hide" ];
  };
in
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "spotify" "spotify-spotx" ];

  environment.systemPackages = [ spotify-spotx ];

  networking.firewall = {
    allowedTCPPorts = [ 57621 ];
    allowedUDPPorts = [ 5353 ];
  };
}
```

### Variant B — pinned and reproducible

> [!WARNING]
> **Update the hashes when you bump the revisions.** `fetchFromGitHub` is a fixed-output derivation, so its `hash` is the identity of the source. Change `rev` without updating `hash` and the build stops with a hash mismatch until you supply the correct value. This is the trade-off for reproducibility: nothing moves under you, but nothing moves without you either.

> [!TIP]
> Pin `rev` to a full commit SHA, not to `"main"`. Pinning a branch name defeats the purpose — the hash still changes on every upstream commit, so you get the failure mode without the benefit. Get both values in one shot:
>
> ```bash
> nix --extra-experimental-features 'nix-command flakes' run nixpkgs#nix-prefetch-github -- SpotX-Official SpotX-Nix --rev main
> ```
>
> Or set `hash = lib.fakeHash;`, build once, and copy the `got: sha256-…` value out of the error message.

```nix
# modules/spotify-spotx.nix
{ config, pkgs, lib, ... }:
let
  # Replace rev with a full commit SHA and hash with the value from
  # `nix-prefetch-github SpotX-Official <repo> --rev <commit>`.
  spotxNix = pkgs.fetchFromGitHub {
    owner = "SpotX-Official";
    repo = "SpotX-Nix";
    rev = "";
    hash = "";
  };

  spotxBash = pkgs.fetchFromGitHub {
    owner = "SpotX-Official";
    repo = "SpotX-Bash";
    rev = "";
    hash = "";
  };

  spotify-spotx = pkgs.callPackage "${spotxNix}/nix/package.nix" {
    spotxSource = spotxBash;
    # spotxArgs = [ "--premium" "--hide" ];
  };
in
{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "spotify" "spotify-spotx" ];

  environment.systemPackages = [ spotify-spotx ];

  networking.firewall = {
    allowedTCPPorts = [ 57621 ];
    allowedUDPPorts = [ 5353 ];
  };
}
```

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
