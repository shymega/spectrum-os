# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ callSpectrumPackage, lseek, start-vmm, lib }:

{
  recurseForDerivations = true;

  lseek = lib.recurseIntoAttrs lseek.tests;

  start-vmm = lib.recurseIntoAttrs start-vmm.tests;

  run-spectrum-vm = lib.recurseIntoAttrs
    (callSpectrumPackage ../../scripts/run-spectrum-vm.nix {}).tests;
}) (_: {})
