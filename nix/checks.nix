# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie

{ config ? import ../nix/eval-config.nix {} }:

{
  recurseForDerivations = true;

  rustfmt = config.pkgs.callPackage (
    { lib, runCommand, rustfmt }:
    runCommand "spectrum-rustfmt" {
      src = lib.cleanSourceWith {
        filter = path: type:
          (builtins.baseNameOf path != "build" && type == "directory")
          || builtins.match ''.*[^/]\.rs'' path != null;
        src = lib.cleanSource ../.;
      };

      nativeBuildInputs = [ rustfmt ];
    } ''
      shopt -s globstar
      rustfmt --check $src/**/*.rs
      touch $out
    ''
  ) {};

  shellcheck = config.pkgs.callPackage (
    { lib, runCommand, shellcheck }:
    runCommand "spectrum-shellcheck" {
      src = lib.cleanSourceWith {
        filter = path: type:
          (builtins.baseNameOf path != "build" && type == "directory")
          || builtins.match ''.*[^/]\.sh'' path != null;
        src = lib.cleanSource ../.;
      };

      nativeBuildInputs = [ shellcheck ];
    } ''
      shopt -s globstar
      shellcheck $src/**/*.sh
      touch $out
    ''
  ) {};
}
