# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix ({ ... } @ args:

{
  recurseForDerivations = true;

  doc-links = import ./doc-links.nix args;

  doc-anchors = import ./doc-anchors.nix args;

  pkg-tests = import ./pkg-tests.nix args;

  no-roothash = import ./no-roothash.nix args;

  reuse = import ./reuse.nix args;

  rustfmt = import ./rustfmt.nix args;

  shellcheck = import ./shellcheck.nix args;

  try = import ./try.nix args;

  wayland = import ./wayland args;
})
