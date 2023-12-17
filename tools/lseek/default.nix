# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

import ../../lib/call-package.nix ({ src, pkgsStatic }:
pkgsStatic.callPackage ({ lib, stdenv, clang-tools }:

stdenv.mkDerivation (finalAttrs: {
  name = "lseek";

  src = lib.fileset.toSource {
    root = ../..;
    fileset = src;
  };
  sourceRoot = "source/tools/lseek";

  makeFlags = [ "prefix=$(out)" ];

  enableParallelBuilding = true;

  passthru.tests = {
    clang-tidy = finalAttrs.finalPackage.overrideAttrs (
      { nativeBuildInputs ? [], ... }:
      {
        nativeBuildInputs = nativeBuildInputs ++ [ clang-tools ];
  
        buildPhase = ''
          clang-tidy --warnings-as-errors='*' lseek.c --
          touch $out
          exit 0
        '';
      }
    );
  };

  meta = with lib; {
    description = "Seek an open file descriptor, then exec.";
    license = licenses.eupl12;
    maintainers = with maintainers; [ qyliss ];
    platforms = platforms.unix;
  };
})

) {}) (_: {})
