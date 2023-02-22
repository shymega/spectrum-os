# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie

{ config ?
  let customPath = builtins.tryEval <spectrum-config>; in
  if customPath.success then import customPath.value
  else if builtins.pathExists ../config.nix then import ../config.nix
  else {}
}:

({ pkgs ? import <nixpkgs> {} }: {
  inherit pkgs;

  src = import ./src.nix { inherit (pkgs) lib; };
}) config
