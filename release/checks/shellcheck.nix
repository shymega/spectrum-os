# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/call-package.nix ({ src, lib, runCommand, shellcheck }:

runCommand "spectrum-shellcheck" {
  src = lib.fileset.toSource {
    root = ../..;
    fileset = src;
  };
  nativeBuildInputs = [ shellcheck ];
} ''
  shopt -s globstar
  shellcheck $src/**/*.sh
  touch $out
'') (_: {})
