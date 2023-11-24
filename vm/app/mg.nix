# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ callSpectrumPackage, pkgsStatic }:

callSpectrumPackage ../make-vm.nix {} {
  sharedDirs.virtiofs0.path = "/ext";
  run = pkgsStatic.callPackage (
    { lib, writeScript, mg }:
    writeScript "run-mg" ''
      #!/bin/execlineb -P
      if { /etc/mdev/wait virtiofs0 }
      ${lib.getExe mg} /run/virtiofs/virtiofs0
    ''
  ) {};
}) (_: {})
