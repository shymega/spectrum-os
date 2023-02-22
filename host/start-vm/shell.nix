# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021 Alyssa Ross <hi@alyssa.is>

import ../../nix/eval-config.nix ({ config, ... }:

with config.pkgs;

(import ./. { inherit config; }).overrideAttrs (
{ nativeBuildInputs ? [], ... }:

{
  nativeBuildInputs = nativeBuildInputs ++ [ rustfmt ];
}))
