# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/eval-config.nix ({ config, src, ... }:
config.pkgs.callPackage ({ runCommand, shellcheck }:

runCommand "spectrum-shellcheck" {
  inherit src;
  nativeBuildInputs = [ shellcheck ];
} ''
  shopt -s globstar
  shellcheck $src/**/*.sh
  touch $out
'') { })
