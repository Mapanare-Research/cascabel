#!/usr/bin/env bash
# Install the released compiler/runtime bundle locally; no compiler checkout needed.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
version=$(tr -d '[:space:]' < .mapanare-version)
case "$version:$(uname -s):$(uname -m)" in
  5.54.0:Linux:x86_64)
    platform=linux-x64
    expected=7cc15e765d25ec6541f94e9a21e992106df13efcf0aa0fe30331f3fe5ba724ab
    ;;
  5.54.0:Darwin:arm64)
    platform=mac-arm64
    expected=941c03a7cdbac1842972837880c534855ef85de72b387bac526c8846cf59bef9
    ;;
  *) echo 'Supported toolchains: Linux x86_64 (including WSL) and macOS arm64, Mapanare 5.54.0.' >&2; exit 1 ;;
esac
destination=.toolchain/mapanare
if [[ -e "$destination" ]]; then
  if [[ -x "$destination/mnc" && -x "$destination/mapanare" && -f "$destination/_internal/runtime/native/mapanare_core.c" ]] &&
     [[ "$("$destination/mnc" version)" == "mapanare $version" ]]; then
    echo "Mapanare $version is already installed in $destination"
    exit 0
  fi
  echo "Unexpected existing toolchain at $destination; move it aside before reinstalling." >&2
  exit 1
fi
mkdir -p .toolchain
temporary=$(mktemp -d .toolchain/download.XXXXXX)
trap 'rm -rf -- "$temporary"' EXIT
asset="mapanare-$version-$platform.tar.gz"
archive="$temporary/$asset"
curl --fail --location --retry 3 \
  "https://github.com/Mapanare-Research/Mapanare/releases/download/v$version/$asset" \
  --output "$archive"
if command -v sha256sum >/dev/null; then
  printf '%s  %s\n' "$expected" "$archive" | sha256sum --check -
else
  printf '%s  %s\n' "$expected" "$archive" | shasum -a 256 --check -
fi
tar -xzf "$archive" -C "$temporary"
[[ "$("$temporary/mapanare/mnc" version)" == "mapanare $version" ]]
test -f "$temporary/mapanare/_internal/runtime/native/mapanare_core.c"
mv "$temporary/mapanare" "$destination"
echo "Installed Mapanare $version in $destination"
