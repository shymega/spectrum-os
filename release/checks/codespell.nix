# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ srcWithNix, lib, runCommand, codespell }:

runCommand "spectrum-codespell" {
  src = lib.fileset.toSource {
    root = ../..;
    fileset = srcWithNix;
  };
  nativeBuildInputs = [ codespell ];
} ''
  cd $src
  codespell
  touch $out
''
) (_: {})
