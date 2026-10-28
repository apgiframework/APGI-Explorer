#!/usr/bin/env bash
# Download the pinned Gitleaks release, verify its SHA-256 against the value pinned here
# (taken from the release's own checksums file), and print the binary path.
# Usage: scripts/install_gitleaks.sh <destination-dir>
set -euo pipefail
VERSION="8.30.0"
dest="${1:?destination directory required}"
case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)  asset="linux_x64";    sha="79a3ab579b53f71efd634f3aaf7e04a0fa0cf206b7ed434638d1547a2470a66e" ;;
  Darwin-arm64)  asset="darwin_arm64"; sha="b251ab2bcd4cd8ba9e56ff37698c033ebf38582b477d21ebd86586d927cf87e7" ;;
  *) echo "unsupported platform $(uname -s)-$(uname -m)" >&2; exit 2 ;;
esac
mkdir -p "$dest"
archive="$dest/gitleaks.tar.gz"
curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/gitleaks_${VERSION}_${asset}.tar.gz" -o "$archive"
actual="$(shasum -a 256 "$archive" | cut -d' ' -f1)"
if [ "$actual" != "$sha" ]; then
  echo "gitleaks checksum mismatch (expected $sha, got $actual)" >&2
  exit 1
fi
tar -xzf "$archive" -C "$dest" gitleaks
echo "$dest/gitleaks"
