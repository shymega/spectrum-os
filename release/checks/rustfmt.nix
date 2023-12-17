# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/call-package.nix ({ src, lib, runCommand, rustfmt }:

runCommand "spectrum-rustfmt" {
  src = lib.fileset.toSource {
    root = ../..;
    fileset = src;
  };
  nativeBuildInputs = [ rustfmt ];
} ''
  shopt -s globstar
  rustfmt --check $src/**/*.rs
  touch $out
'') (_: {})
