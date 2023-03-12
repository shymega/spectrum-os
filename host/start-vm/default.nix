# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix ({ config, src, ... }: config.pkgs.callPackage (
{ lib, stdenv, meson, ninja, rustc }:

stdenv.mkDerivation {
  name = "start-vm";

  inherit src;
  sourceRoot = "source/host/start-vm";

  nativeBuildInputs = [ meson ninja rustc ];

  doCheck = true;
}
) { })
