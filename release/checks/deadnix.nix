# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023-2024 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ srcWithNix, lib, runCommand, deadnix }:

runCommand "spectrum-deadnix" {
  src = lib.fileset.toSource {
    root = ../..;
    fileset = lib.fileset.intersection srcWithNix
      (lib.fileset.fileFilter ({ hasExt, ... }: hasExt "nix") ../..);
  };
  nativeBuildInputs = [ deadnix ];
} ''
  deadnix -Lf $src
  touch $out
'') (_: {})
