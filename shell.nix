# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

import lib/eval-config.nix ({ config, ... }: with config.pkgs;

mkShell {
  nativeBuildInputs = [ b4 reuse ];
})
