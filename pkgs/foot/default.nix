# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

import ../../lib/overlay-package.nix "foot" ({ final, super }:

super.foot.overrideAttrs ({ patches ? [], ... }: {
  patches = patches ++ [
    ./Add-support-for-opening-an-existing-PTY.patch
  ];
}))
