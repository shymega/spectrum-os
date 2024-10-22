# SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2022 Unikie
# SPDX-License-Identifier: MIT

import ../lib/call-package.nix

({ callSpectrumPackage, src, lib, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  name = "spectrum-docs";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.intersection src ./.;
  };
  sourceRoot = "source/Documentation";

  buildPhase = ''
    runHook preBuild
    jekyll build --disable-disk-cache -b /doc -d $out
    runHook postBuild
  '';

  dontInstall = true;

  nativeBuildInputs = [ (callSpectrumPackage ./jekyll.nix {}) ];
}) (_: {})
