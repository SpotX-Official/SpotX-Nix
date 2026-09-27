#!/usr/bin/env bash

set -euo pipefail

appPath="${1:-result/Applications/Spotify.app}"
appBinary="${appPath}/Contents/MacOS/Spotify"
[[ -d "${appPath}" ]] || { echo "Spotify.app not found: ${appPath}" >&2; exit 1; }
[[ -f "${appBinary}" ]] || { echo "Spotify executable not found: ${appBinary}" >&2; exit 1; }
archs=$(lipo -archs "${appBinary}")
[[ " ${archs} " == *" arm64 "* ]] || { echo "Expected an arm64 Spotify executable, found: ${archs}" >&2; exit 1; }
leftover=$(find "${appPath}" -type f \( -name '*.bak' -o -name '.spotx*' \) -print -quit)
[[ -z "${leftover}" ]] || { echo "Unexpected SpotX build artifact: ${leftover}" >&2; exit 1; }
while IFS= read -r -d '' file; do
  file -b "${file}" | grep -q 'Mach-O' || continue
  reference=$(otool -L "${file}" | grep -F '/nix/store/' || true)
  [[ -z "${reference}" ]] || { echo "Unexpected Nix store reference in ${file}:" >&2; echo "${reference}" >&2; exit 1; }
done < <(find "${appPath}" -type f -print0)
/usr/bin/codesign --verify --deep --strict --verbose=2 "${appPath}"
echo "Verified arm64 Spotify application and complete bundle signature"
