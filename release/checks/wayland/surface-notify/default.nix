# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../../../lib/call-package.nix (
{ src, lib, stdenv, meson, ninja, pkg-config
, libxkbcommon, pixman, wayland, westonLite
}:

stdenv.mkDerivation {
  name = "surface-notify";

  src = lib.fileset.toSource {
    root = ../../../..;
    fileset = src;
  };
  sourceRoot = "source/release/checks/wayland/surface-notify";

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ libxkbcommon pixman wayland westonLite ];
}
) (_: {})
