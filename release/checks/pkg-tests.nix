# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ callSpectrumPackage, lseek, start-vm, lib }:

{
  recurseForDerivations = true;

  lseek = lib.recurseIntoAttrs lseek.tests;

  start-vm = lib.recurseIntoAttrs start-vm.tests;

  run-spectrum-vm = lib.recurseIntoAttrs
    (callSpectrumPackage ../../scripts/run-spectrum-vm.nix {}).tests;
}) (_: {})
