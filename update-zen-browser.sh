#!/usr/bin/env bash

upstream=$(./new-version.sh | cat -)

echo "Updating to $upstream"

baseUrl="https://github.com/zen-browser/desktop/releases/download/$upstream"

sed -i "s/version = \".*\"/version = \"$upstream\"/" ./flake.nix

sha256=$(nix-prefetch-url --type sha256 --unpack "$baseUrl/zen.linux-x86_64.tar.bz2")
sed -i "s/download.sha256 = \".*\"/download.sha256 = \"$sha256\"/" ./flake.nix

nix flake update
nix build .#
