# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/call-package.nix ({ src, runCommand, rustfmt }:

runCommand "spectrum-rustfmt" {
  inherit src;
  nativeBuildInputs = [ rustfmt ];
} ''
  shopt -s globstar
  rustfmt --check $src/**/*.rs
  touch $out
'') (_: {})
