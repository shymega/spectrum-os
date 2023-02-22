# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

# The empty list of attribute set arguments is required, because
# otherwise Nix will not pass arguments supplied on the command line
# with --arg/--argstr.
callback: { ... } @ args:

callback (args // rec {
  config = ({ pkgs ? import <nixpkgs> {} }: {
    inherit pkgs;
  }) args.config or (let customPath = builtins.tryEval <spectrum-config>; in
  if customPath.success then import customPath.value
  else if builtins.pathExists ../config.nix then import ../config.nix
  else {})
;

  src = import ./src.nix { inherit (config.pkgs) lib; };
})
