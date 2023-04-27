# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2022 Unikie
# SPDX-License-Identifier: MIT

import ../lib/eval-config.nix ({ config, src, ... }: config.pkgs.callPackage (

{ stdenvNoCC, jekyll, drawio-headless }:

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

  nativeBuildInputs = [ jekyll drawio-headless ];

  passthru = { inherit jekyll; };
}
) {
  jekyll = import ./jekyll.nix { inherit config; };
})
