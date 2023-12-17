# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ src, lib, runCommand, reuse }:

runCommand "spectrum-reuse" {
  src = lib.fileset.toSource {
    root = ../..;
    fileset = src;
  };
  nativeBuildInputs = [ reuse ];
} ''
  reuse --root $src lint
  touch $out
''
) (_: {})
