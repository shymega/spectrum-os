# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ src, stdenv, meson, ninja, rustc, clippy }:

stdenv.mkDerivation (finalAttrs: {
  name = "start-vm";

  inherit src;
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
  };
})
) (_: {})
