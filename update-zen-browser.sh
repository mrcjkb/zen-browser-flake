#!/usr/bin/env bash

upstream=$(./new-version.sh | cat -)

echo "Updating to $upstream"

baseUrl="https://github.com/zen-browser/desktop/releases/download/$upstream"

sed -i "s/version = \".*\"/version = \"$upstream\"/" ./flake.nix

specfic=$(nix-prefetch-url --type sha256 --unpack "$baseUrl/zen.linux-specific.tar.bz2")
sed -i "s/specific.sha256 = \".*\"/specific.sha256 = \"$specfic\"/" ./flake.nix

generic=$(nix-prefetch-url --type sha256 --unpack "$baseUrl/zen.linux-generic.tar.bz2")
sed -i "s/generic.sha256 = \".*\"/generic.sha256 = \"$generic\"/" ./flake.nix

nix flake update
nix build .#specific
nix build .#generic
