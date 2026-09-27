# SpotX-Nix

Declarative Nix packaging for [SpotX-Bash](https://github.com/SpotX-Official/SpotX-Bash).

SpotX-Nix patches Spotify while its Nix derivation is being built. It does not modify an existing package in `/nix/store`.

## Supported platforms

| Platform | Support |
| --- | --- |
| `x86_64-linux` | Supported |
| `aarch64-darwin` | Supported |
| `aarch64-linux` | Unsupported because Spotify does not provide an ARM Linux client |
| `x86_64-darwin` | Unsupported because Nixpkgs does not currently package Spotify for Intel macOS |

macOS support is currently limited to Apple Silicon. Regular SpotX-Bash still supports Intel macOS installations outside Nix.

## Flake input

Add SpotX-Nix to your flake inputs:

```nix
inputs.spotx-nix = {
  url = "github:SpotX-Official/SpotX-Nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

## NixOS

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

## nix-darwin

Use the same overlay and package in a nix-darwin configuration:

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

## Home Manager

Use the overlay and add the package to `home.packages`:

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

  home.packages = [ pkgs.spotify-spotx ];
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

1. The latest SpotX-Bash supported version is equal to or newer than the Nixpkgs Spotify version on every supported platform.
2. The patched Spotify derivation builds successfully on Linux and Apple Silicon macOS.
3. Apple `codesign` verifies the complete Darwin application bundle.

If Nixpkgs provides a newer Spotify version than SpotX-Bash supports, no repository changes are made. The scheduled workflow checks again six hours later.
