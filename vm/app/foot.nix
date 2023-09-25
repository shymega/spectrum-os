# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/eval-config.nix ({ config, ... }:

import ../make-vm.nix { inherit config; } {
  wayland = true;
  run = config.pkgs.pkgsStatic.callPackage (
    { writeScript }:
    writeScript "run-foot" ''
      #!/bin/execlineb -P
      foreground { mkdir /run/user }
      foreground {
        umask 077
        mkdir /run/user/0
      }
      if { /etc/mdev/wait card0 }
      export XDG_RUNTIME_DIR /run/user/0
      ${config.pkgs.pkgsMusl.wayland-proxy-virtwl}/bin/wayland-proxy-virtwl --virtio-gpu --
      ${config.pkgs.pkgsMusl.foot}/bin/foot
    ''
  ) { };
})
