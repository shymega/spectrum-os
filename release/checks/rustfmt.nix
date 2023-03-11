# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/eval-config.nix ({ config, src, ... }:
config.pkgs.callPackage ({ runCommand, rustfmt }:

runCommand "spectrum-rustfmt" {
  inherit src;
  nativeBuildInputs = [ rustfmt ];
} ''
  shopt -s globstar
  rustfmt --check $src/**/*.rs
  touch $out
'') { })
