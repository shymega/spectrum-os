# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

import ../lib/call-package.nix ({ callSpectrumPackage, pkgs }:

import ../vm-lib/make-vm.nix {
  inherit pkgs;
  basePaths = (callSpectrumPackage ../img/app {}).packagesSysroot;
}) (_: {})
