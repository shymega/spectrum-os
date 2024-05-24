# SPDX-FileCopyrightText: 2023-2024 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

attr: callback:

{ ... } @ args:

if args ? final && args ? super then
  callback args
else
  # Auto-called from CLI.
  # Since overlaid packages can affect other packages they depend on,
  # we have to get the package out of the applied overlay.
  let
    pkgs = import ../pkgs/overlaid.nix args;
    inherit (pkgs) lib;
  in
  lib.getAttrFromPath attr pkgs
