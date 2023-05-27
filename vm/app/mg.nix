# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

{ config ? import ../../../nix/eval-config.nix {} }:

import ../make-vm.nix { inherit config; } {
  sharedDirs.virtiofs0.path = "/ext";
  run = config.pkgs.pkgsStatic.callPackage (
    { writeScript, mg }:
    writeScript "run-mg" ''
      #!/bin/execlineb -P
      if { /etc/mdev/wait virtiofs0 }
      ${mg}/bin/mg /run/virtiofs/virtiofs0
    ''
  ) { };
}
