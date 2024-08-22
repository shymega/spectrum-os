# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/call-package.nix (
{ callSpectrumPackage, pkgsMusl }:

callSpectrumPackage ../make-vm.nix {} {
  run = pkgsMusl.callPackage (
    { lib, writeScript, gnome-text-editor, wayland-proxy-virtwl }:
    writeScript "run-gnome-text-editor" ''
      #!/bin/execlineb -P
      foreground { mkdir /run/user }
      foreground {
        umask 077
        mkdir /run/user/0
      }
      if { /etc/mdev/wait card0 }
      export GDK_DEBUG portals
      export XDG_RUNTIME_DIR /run/user/0
      ${lib.getExe wayland-proxy-virtwl} --virtio-gpu --
      ${lib.getExe gnome-text-editor}
    ''
  ) {};
}) (_: {})
