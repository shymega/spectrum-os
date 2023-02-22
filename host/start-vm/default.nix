# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

{ config ? import ../../nix/eval-config.nix {} }: config.pkgs.callPackage (
{ lib, stdenv, meson, ninja, rustc }:

let
  inherit (lib) hasSuffix;
in

stdenv.mkDerivation {
  name = "start-vm";

  inherit (config) src;
  sourceRoot = "source/host/start-vm";

  nativeBuildInputs = [ meson ninja rustc ];

  doCheck = true;
}
) { }
