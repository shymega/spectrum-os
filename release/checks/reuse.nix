# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ src, runCommand, reuse }:

runCommand "spectrum-reuse" {
  inherit src;
  nativeBuildInputs = [ reuse ];
} ''
  reuse --root $src lint
  touch $out
''
) (_: {})
