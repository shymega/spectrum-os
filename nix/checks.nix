# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie

{ config ? import ../nix/eval-config.nix {} }:

{
  recurseForDerivations = true;

  doc-links = config.pkgs.callPackage (
    { lib, runCommand, ruby, wget }:
    runCommand "spectrum-doc-links" {
      doc = import ../Documentation { inherit config; };
      nativeBuildInputs = [ ruby wget ];
    } ''
      mkdir root
      ln -s $doc root/doc
      ruby -run -e httpd -- --port 4000 root &
      wget -r -nv --delete-after --no-parent --retry-connrefused http://localhost:4000/doc/
      touch $out
    ''
  ) {};

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
