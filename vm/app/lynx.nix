# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix ({ config, ... }:

import ../make-vm.nix { inherit config; } {
  providers.net = [ "netvm" ];
  run = config.pkgs.pkgsStatic.callPackage (
    { lib, writeScript, lynx }:
    writeScript "run-lynx" ''
      #!/bin/execlineb -P
      if { /etc/mdev/wait network-online }
      ${lib.getExe lynx} https://spectrum-os.org
    ''
  ) { };
})
