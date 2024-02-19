# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ src, lib, stdenv, meson, ninja, rustc, clippy, run-spectrum-vm }:

stdenv.mkDerivation (finalAttrs: {
  name = "start-vm";

  src = lib.fileset.toSource {
    root = ../..;
    fileset = lib.fileset.intersection src ./.;
  };
  sourceRoot = "source/host/start-vm";

  nativeBuildInputs = [ meson ninja rustc ];

  mesonFlags = [ "-Dwerror=true" ];

  doCheck = true;

  passthru.tests = {
    clippy = finalAttrs.finalPackage.overrideAttrs (
      { nativeBuildInputs ? [], ... }:
      {
        nativeBuildInputs = nativeBuildInputs ++ [ clippy ];
        RUSTC = "clippy-driver";
        postBuild = ''touch $out && exit 0'';
      }
    );

    run = run-spectrum-vm.override { start-vm = finalAttrs.finalPackage; };
  };

  meta = {
    mainProgram = "start-vm";
  };
})
) (_: {})
