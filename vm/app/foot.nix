# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ callSpectrumPackage, lib, pkgsMusl }:

callSpectrumPackage ../make-vm.nix {} {
  run = lib.getExe pkgsMusl.foot;
}) (_: {})
