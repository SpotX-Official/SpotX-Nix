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
  DarwinTools,
  sigtool,
  system_cmds,
  stdenv,
  spotxArgs ? [ ],
}:
let
  spotxVersionLine =
    lib.findFirst (line: lib.hasPrefix "buildVer=" line)
      (throw "Unable to determine the SpotX-Bash supported version")
      (lib.splitString "\n" (builtins.readFile "${spotxSource}/spotx.sh"));
  spotxVersion = lib.removeSuffix "\"" (lib.removePrefix "buildVer=\"" spotxVersionLine);

  inherit (stdenv.hostPlatform) isDarwin;

  clientPath = if isDarwin then "$out/Applications" else "$out/share/spotify";
  clientRoot = if isDarwin then "${clientPath}/Spotify.app/Contents" else clientPath;
  clientBinary = if isDarwin then "${clientRoot}/MacOS/Spotify" else "${clientRoot}/spotify";
  xpuiPath = if isDarwin then "${clientRoot}/Resources/Apps" else "${clientRoot}/Apps";

  platformArgs = lib.optionals isDarwin [
    "-S"
    "-F"
    spotify.version
  ];
in
spotify.overrideAttrs (old: {
  pname = "spotify-spotx";

  dontStrip = isDarwin || (old.dontStrip or false);

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
    ]
    ++ lib.lists.optionals isDarwin [
      DarwinTools
      system_cmds
    ];

  postInstall =
    (old.postInstall or "")
    + ''
      export HOME="$TMPDIR/spotx-home"
      export SPOTX_BUILD_MODE=true
      mkdir -p "$HOME"

      install -m755 ${spotxSource}/spotx.sh "$NIX_BUILD_TOP/spotx.sh"
    ''
    + lib.optionalString isDarwin ''
      chmod -R u+w "$out/Applications/Spotify.app"

      substituteInPlace "$NIX_BUILD_TOP/spotx.sh" \
        --replace-fail /usr/bin/xattr true
    ''
    + ''
      ${lib.getExe bash} "$NIX_BUILD_TOP/spotx.sh" -P "${clientPath}" \
        ${lib.escapeShellArgs (platformArgs ++ spotxArgs)}

      rm -f "${clientBinary}.bak"
      rm -f "${xpuiPath}/xpui.bak"
    ''
    + lib.optionalString isDarwin ''
      ${lib.getExe' sigtool "codesign"} --force --sign - \
        --identifier com.spotify.client "${clientBinary}"
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
