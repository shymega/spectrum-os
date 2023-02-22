# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

import ../../nix/eval-config.nix ({ config, src, ... }: config.pkgs.callPackage (
{ lib, stdenv, meson, ninja, rustc }:

let
  inherit (lib) hasSuffix;
in

stdenv.mkDerivation {
  name = "start-vm";

  inherit src;
  sourceRoot = "source/host/start-vm";

  nativeBuildInputs = [ meson ninja rustc ];

  doCheck = true;
}
) { })
