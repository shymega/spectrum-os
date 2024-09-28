# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ callSpectrumPackage, lib, firefox }:

callSpectrumPackage ../make-vm.nix {} {
  providers.net = [ "user.netvm" ];
  run = lib.getExe firefox;
}) (_: {})
