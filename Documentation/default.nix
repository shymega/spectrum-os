# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2022 Unikie
# SPDX-License-Identifier: MIT

{ config ? import ../nix/eval-config.nix {} }: config.pkgs.callPackage (

{ lib, stdenvNoCC, jekyll, drawio-headless }:

stdenvNoCC.mkDerivation {
  name = "spectrum-docs";

  inherit (config) src;
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
}
