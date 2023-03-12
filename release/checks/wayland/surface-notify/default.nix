# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../../../lib/eval-config.nix ({ config, src, ... }: config.pkgs.callPackage (

{ lib, stdenv, meson, ninja, pkg-config
, libxkbcommon, pixman, wayland, westonLite
}:

stdenv.mkDerivation {
  name = "surface-notify";

  inherit src;
  sourceRoot = "source/release/checks/wayland/surface-notify";

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ libxkbcommon pixman wayland westonLite ];
}
) { })
