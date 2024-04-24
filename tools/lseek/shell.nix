# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2024 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ callSpectrumPackage, clang-tools }:

(callSpectrumPackage ./. {}).overrideAttrs (
{ nativeBuildInputs ? [], ... }:

{
  nativeBuildInputs = nativeBuildInputs ++ [ clang-tools ];
})) (_: {})
