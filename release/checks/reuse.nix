# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ srcWithNix, lib, runCommand, reuse }:

runCommand "spectrum-reuse" {
  src = lib.fileset.toSource {
    root = ../..;
    fileset = srcWithNix;
  };
  nativeBuildInputs = [ reuse ];
} ''
  reuse --root $src lint
  touch $out
''
) (_: {})
