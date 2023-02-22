# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

import ../lib/eval-config.nix ({ config, ... }: config.pkgs.callPackage (

{ bundlerApp }:

bundlerApp {
  pname = "jekyll";
  gemdir = ./.;
  exes = [ "jekyll" ];
}
) { })
