# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ callSpectrumPackage, writeScript }:

callSpectrumPackage ../make-vm.nix {} {
  run = writeScript "run-poweroff" ''
    #!/bin/execlineb -P
    poweroff -f
  '';
}) (_: {})
