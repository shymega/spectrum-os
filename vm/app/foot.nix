# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ callSpectrumPackage, lib, foot }:

callSpectrumPackage ../make-vm.nix {} {
  type = "nix";
  run = lib.getExe foot;
}) (_: {})
