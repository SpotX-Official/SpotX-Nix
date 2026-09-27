#!/usr/bin/env bash

set -euo pipefail

system="${1:-${NIX_SYSTEM:-x86_64-linux}}"
case "${system}" in
  x86_64-linux|aarch64-darwin) ;;
  *)
    echo "Unsupported system: ${system}" >&2
    exit 1
    ;;
esac

version_key() {
  local version="${1%%.g*}" major minor patch build
  IFS='.' read -r major minor patch build <<< "${version}"
  printf '%08d%08d%08d%08d\n' \
    "$((10#${major:-0}))" \
    "$((10#${minor:-0}))" \
    "$((10#${patch:-0}))" \
    "$((10#${build:-0}))"
}

spotxVersion="${SPOTX_VERSION_OVERRIDE:-$(nix eval --raw ".#packages.${system}.spotify-spotx.spotxVersion")}"
spotifyVersion="${SPOTIFY_VERSION_OVERRIDE:-$(nix eval --raw ".#packages.${system}.spotify-spotx.spotifyVersion")}"
spotxKey=$(version_key "${spotxVersion}")
spotifyKey=$(version_key "${spotifyVersion}")
supported='true'
[[ "${spotxKey}" < "${spotifyKey}" ]] && supported='false'
echo "SpotX-Bash supports: ${spotxVersion}"
echo "Nixpkgs provides:    ${spotifyVersion}"
echo "System:              ${system}"
echo "Compatible:          ${supported}"
[[ -n "${GITHUB_OUTPUT:-}" ]] && {
  echo "spotx-version=${spotxVersion}" >> "${GITHUB_OUTPUT}"
  echo "spotify-version=${spotifyVersion}" >> "${GITHUB_OUTPUT}"
  echo "supported=${supported}" >> "${GITHUB_OUTPUT}"
}
[[ "${REQUIRE_SUPPORTED:-false}" == "true" && "${supported}" != "true" ]] && {
  echo "Nixpkgs Spotify is newer than the latest SpotX-Bash-supported version." >&2
  exit 1
}
exit 0
