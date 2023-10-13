# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix ({ config, ... }:

import ../make-vm.nix { inherit config; } {
  sharedDirs.virtiofs0.path = "/ext";
  run = config.pkgs.pkgsStatic.callPackage (
    { lib, writeScript, mg }:
    writeScript "run-mg" ''
      #!/bin/execlineb -P
      if { /etc/mdev/wait virtiofs0 }
      ${lib.getExe mg} /run/virtiofs/virtiofs0
    ''
  ) { };
})
