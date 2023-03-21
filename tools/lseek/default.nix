# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

import ../../lib/eval-config.nix ({ config, src, ... }: config.pkgs.pkgsStatic.callPackage (

{ lib, stdenv, clang-tools }:

let self = stdenv.mkDerivation {
  name = "lseek";

  inherit src;
  sourceRoot = "source/tools/lseek";

  makeFlags = [ "prefix=$(out)" ];

  enableParallelBuilding = true;

  passthru.tests = {
    clang-tidy = self.overrideAttrs ({ nativeBuildInputs ? [], ... }: {
      nativeBuildInputs = nativeBuildInputs ++ [ clang-tools ];

      buildPhase = ''
        clang-tidy --warnings-as-errors='*' lseek.c --
        touch $out
        exit 0
      '';
    });
  };

  meta = with lib; {
    description = "Seek an open file descriptor, then exec.";
    license = licenses.eupl12;
    maintainers = with maintainers; [ qyliss ];
    platforms = platforms.unix;
  };
}; in self

) { })
