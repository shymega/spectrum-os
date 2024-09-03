# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ callSpectrumPackage, pkgsStatic }:

callSpectrumPackage ../make-vm.nix {} {
  providers.net = [ "user.netvm" ];
  run = pkgsStatic.callPackage (
    { lib, writeScript, lynx }:
    writeScript "run-lynx" ''
      #!/bin/execlineb -P
      if { /etc/mdev/wait network-online }
      ${lib.getExe lynx} https://spectrum-os.org
    ''
  ) {};
}) (_: {})
