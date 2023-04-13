# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix ({ config, src, ... }: config.pkgs.callPackage (
{ lib, stdenv, meson, ninja, rustc, clippy }:

lib.fix (self: stdenv.mkDerivation {
  name = "start-vm";

  inherit src;
  sourceRoot = "source/host/start-vm";

  nativeBuildInputs = [ meson ninja rustc ];

  doCheck = true;

  passthru.tests = {
    clippy = self.overrideAttrs ({ nativeBuildInputs ? [], ... }: {
      nativeBuildInputs = nativeBuildInputs ++ [ clippy ];
      RUSTC = "clippy-driver";
      postBuild = ''touch $out && exit 0'';
    });
  };
})
) { })
