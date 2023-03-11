# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix ({ config, src, ... }:
config.pkgs.callPackage ({ runCommand, reuse }:

runCommand "spectrum-reuse" {
  inherit src;
  nativeBuildInputs = [ reuse ];
} ''
  reuse --root $src lint
  touch $out
''
) { })
