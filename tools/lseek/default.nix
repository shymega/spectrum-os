# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

import ../../lib/eval-config.nix ({ config, src, ... }: config.pkgs.pkgsStatic.callPackage (

{ lib, stdenv }:

stdenv.mkDerivation {
  name = "lseek";

  inherit src;
  sourceRoot = "source/tools/lseek";

  makeFlags = [ "prefix=$(out)" ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Seek an open file descriptor, then exec.";
    license = licenses.eupl12;
    maintainers = with maintainers; [ qyliss ];
    platforms = platforms.unix;
  };
}

) { })
