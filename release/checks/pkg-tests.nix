# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix ({ config, ... }:

{
  recurseForDerivations = true;

  lseek = config.pkgs.lib.recurseIntoAttrs
    (import ../../tools/lseek { inherit config; }).tests;

  start-vm = config.pkgs.lib.recurseIntoAttrs
    (import ../../host/start-vm { inherit config; }).tests;
})
