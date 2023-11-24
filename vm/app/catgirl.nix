# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ callSpectrumPackage, pkgsStatic }:

callSpectrumPackage ../make-vm.nix {} {
  providers.net = [ "netvm" ];
  run = pkgsStatic.callPackage (
    { lib, writeScript, catgirl }:
    writeScript "run-catgirl" ''
      #!/bin/execlineb -P
      if { /etc/mdev/wait network-online }
      foreground { printf "IRC nick (to join #spectrum): " }
      backtick -E nick { head -1 }
      ${lib.getExe catgirl} -h irc.libera.chat -j "#spectrum" -n $nick
    ''
  ) {};
}) (_: {})
