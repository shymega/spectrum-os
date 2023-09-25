# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/call-package.nix (
{ callSpectrumPackage, lib, writeScript, pkgsMusl }:

callSpectrumPackage ../make-vm.nix {} {
  run = writeScript "run-gnome-text-editor" ''
    #!/bin/execlineb -P
    export GDK_DEBUG portals
    ${lib.getExe pkgsMusl.gnome-text-editor}
  '';
}) (_: {})
