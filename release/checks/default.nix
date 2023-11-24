# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ callSpectrumPackage }:

{
  recurseForDerivations = true;

  doc-links = callSpectrumPackage ./doc-links.nix {};

  doc-anchors = callSpectrumPackage ./doc-anchors.nix {};

  pkg-tests = callSpectrumPackage ./pkg-tests.nix {};

  no-roothash = callSpectrumPackage ./no-roothash.nix {};

  reuse = callSpectrumPackage ./reuse.nix {};

  rustfmt = callSpectrumPackage ./rustfmt.nix {};

  shellcheck = callSpectrumPackage ./shellcheck.nix {};

  try = callSpectrumPackage ./try.nix {};

  wayland = callSpectrumPackage ./wayland {};
}) (_: {})
