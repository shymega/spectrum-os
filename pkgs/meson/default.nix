# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

import ../../lib/overlay-package.nix "meson" ({ final, super }:

super.meson.overrideAttrs ({ patches ? [], ... }: {
  patches = patches ++ [
    (final.fetchpatch {
      url = "https://github.com/mesonbuild/meson/commit/1ca2c74d16c3f5987f686e358b58ce5d2253ce9b.patch";
      hash = "sha256-ZnYF9IDrroa4r4YNZxDnGe+KRnaYmBQOe2PvcZb2A4Y=";
    })
  ];
}))
