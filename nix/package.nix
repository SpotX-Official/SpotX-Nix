{
  lib,
  bash,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  perl,
  spotify,
  unzip,
  util-linux,
  zip,
  spotxSource,
  spotxArgs ? [ ],
}:
let
  spotxVersionLine = lib.findFirst (
    line: lib.hasPrefix "buildVer=" line
  ) (throw "Unable to determine the SpotX-Bash supported version") (
    lib.splitString "\n" (builtins.readFile "${spotxSource}/spotx.sh")
  );
  spotxVersion = lib.removeSuffix "\"" (lib.removePrefix "buildVer=\"" spotxVersionLine);
in
spotify.overrideAttrs (old: {
  pname = "spotify-spotx";

  nativeBuildInputs =
    (old.nativeBuildInputs or [ ])
    ++ [
      bash
      coreutils
      findutils
      gnugrep
      gnused
      perl
      unzip
      util-linux
      zip
    ];

  postInstall =
    (old.postInstall or "")
    + ''
      export HOME="$TMPDIR/spotx-home"
      export SPOTX_BUILD_MODE=true
      mkdir -p "$HOME"
      ${lib.getExe bash} ${spotxSource}/spotx.sh -P "$out/share/spotify" ${lib.escapeShellArgs spotxArgs}
      rm -f "$out/share/spotify/spotify.bak"
      rm -f "$out/share/spotify/Apps/xpui.bak"
    '';

  passthru = (old.passthru or { }) // {
    inherit spotxVersion;
    spotifyVersion = spotify.version;
    unpatchedSpotify = spotify;
  };

  meta = (old.meta or { }) // {
    description = "Spotify patched with SpotX-Bash";
  };
})
