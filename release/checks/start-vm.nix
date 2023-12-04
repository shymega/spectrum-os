# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ callSpectrumPackage, runCommand }:

runCommand "start-vm-test" {} ''
  ${callSpectrumPackage ../../scripts/run-spectrum-vm.nix {}} > $out
'') (_: {})
