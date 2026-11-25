#!/usr/bin/env bash
# Builds Cubbyhole's apt repository (flat layout) for one release.
#
#   scripts/apt-repo.sh <tag> <deb file> <output dir> [<path in sources.list, default raw/apt>]
#
# The .deb itself stays on the GitHub release. The repository only holds the signed index:
#   <out>/Packages, Packages.gz, Release, Release.gpg, InRelease, cubbyhole-archive-key.asc
# Users' apt reads it as
#   deb [signed-by=…] https://github.com/semicolonconsulting/cubbyhole-release raw/apt/
# so the index is fetched from the "apt" branch and each package's Filename,
# releases/download/<tag>/<file>, resolves to the release asset under the same base URL.
#
# Signs with the key imported into gpg; pass its passphrase in APT_GPG_PASSPHRASE.
set -euo pipefail
tag=$1 deb=$2 out=$3 dist=${4:-raw/apt}
mkdir -p "$out"
name=$(basename "$deb")

{
  dpkg-deb -f "$deb"
  echo "Filename: releases/download/$tag/$name"
  echo "Size: $(stat -c %s "$deb")"
  echo "MD5sum: $(md5sum "$deb" | cut -d' ' -f1)"
  echo "SHA1: $(sha1sum "$deb" | cut -d' ' -f1)"
  echo "SHA256: $(sha256sum "$deb" | cut -d' ' -f1)"
  echo "SHA512: $(sha512sum "$deb" | cut -d' ' -f1)"
} > "$out/Packages"
gzip -9nkf "$out/Packages"
# by-hash copies: GitHub's raw file cache can briefly serve a new InRelease with an old Packages
# (or the reverse). apt fetches the index by its hash instead, so a mixed cache can't break it.
# Older by-hash files already in <out> are kept for the same reason.
for f in Packages Packages.gz; do
  for algo in SHA256:sha256sum SHA512:sha512sum; do
    mkdir -p "$out/by-hash/${algo%%:*}"
    cp "$out/$f" "$out/by-hash/${algo%%:*}/$(${algo##*:} "$out/$f" | cut -d' ' -f1)"
  done
done

arch=$(dpkg-deb -f "$deb" Architecture)
{
  echo "Origin: Cubbyhole"
  echo "Label: Cubbyhole"
  # apt checks these against the path in sources.list and warns on every update when they differ.
  echo "Suite: $dist"
  echo "Codename: $dist"
  echo "Architectures: $arch"
  echo "Date: $(LC_ALL=C date -Ru)"
  echo "Description: Cubbyhole, your web apps in one window"
  echo "Acquire-By-Hash: yes"
  for algo in MD5Sum:md5sum SHA1:sha1sum SHA256:sha256sum SHA512:sha512sum; do
    echo "${algo%%:*}:"
    for f in Packages Packages.gz; do
      printf ' %s %s %s\n' "$(${algo##*:} "$out/$f" | cut -d' ' -f1)" "$(stat -c %s "$out/$f")" "$f"
    done
  done
} > "$out/Release"

sign=(gpg --batch --yes --pinentry-mode loopback --passphrase "${APT_GPG_PASSPHRASE:-}")
"${sign[@]}" --clearsign -o "$out/InRelease" "$out/Release"
"${sign[@]}" --armor --detach-sign -o "$out/Release.gpg" "$out/Release"
gpg --armor --export > "$out/cubbyhole-archive-key.asc"
