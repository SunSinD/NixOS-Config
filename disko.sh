#!/usr/bin/env bash

# This script runs from the NixOS live ISO.
# It partitions your disk using disko-config.nix,
# then installs NixOS directly from your GitHub repo.
# You never need to manually partition or clone anything.

set -e  # Stop immediately if any command fails

sudo nix --experimental-features "nix-command flakes" run \
  'github:nix-community/disko/latest#disko-install' -- \
  --flake 'github:SunSinD/nixos-config#SunSD' \
  --write-efi-boot-entries \
  --disk main /dev/sda
