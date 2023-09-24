# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix ({ config, ... }:

import ../make-vm.nix { inherit config; } {
  wayland = true;
  run = config.pkgs.pkgsStatic.callPackage (
    { writeScript, hello-wayland }:
    writeScript "run-hello-wayland" ''
      #!/bin/execlineb -P
      foreground { mkdir /run/user }
      foreground {
        umask 077
        mkdir /run/user/0
      }
      if { /etc/mdev/wait card0 }
      export XDG_RUNTIME_DIR /run/user/0

      # No pkgsStatic.wayland-proxy-virtwl:
      # https://github.com/nix-ocaml/nix-overlays/issues/698
      ${config.pkgs.pkgsMusl.wayland-proxy-virtwl}/bin/wayland-proxy-virtwl --virtio-gpu

      ${hello-wayland}/bin/hello-wayland
    ''
  ) { };
})
