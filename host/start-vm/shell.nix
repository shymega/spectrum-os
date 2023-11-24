# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ callSpectrumPackage, clippy, rustfmt }:

(callSpectrumPackage ./. {}).overrideAttrs (
{ nativeBuildInputs ? [], ... }:

{
  hardeningDisable = [ "fortify" ];

  nativeBuildInputs = nativeBuildInputs ++ [ clippy rustfmt ];
})) (_: {})
