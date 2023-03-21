# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix ({ config, src, ... }:

{
  recurseForDerivations = true;

  lseek = config.pkgs.lib.recurseIntoAttrs
    (import ../../tools/lseek { inherit config; }).tests;
})
