# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

import ../lib/call-package.nix (
{ bundlerApp }:

bundlerApp {
  pname = "jekyll";
  gemdir = ./.;
  exes = [ "jekyll" ];
}
) (_: {})
