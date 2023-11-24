# SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2022 Unikie
# SPDX-License-Identifier: MIT

import ../lib/call-package.nix

({ callSpectrumPackage, src, stdenvNoCC, jekyll, drawio-headless }:

stdenvNoCC.mkDerivation {
  name = "spectrum-docs";

  inherit src;
  sourceRoot = "source/Documentation";

  buildPhase = ''
    runHook preBuild
    scripts/build.sh -d $out
    runHook postBuild
  '';

  dontInstall = true;

  nativeBuildInputs = [
    (callSpectrumPackage ./jekyll.nix {})
    drawio-headless
  ];
}) (_: {})
