# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

import ../lib/eval-config.nix ({ config, ... }:

import ../vm-lib/make-vm.nix {
  inherit (config) pkgs;
  basePaths = (import ../img/app { inherit config; }).packagesSysroot;
})
