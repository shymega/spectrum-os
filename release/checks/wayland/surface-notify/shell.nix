# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

{ ... } @ args:

(import ./. args).overrideAttrs ({ hardeningDisable ? [], ... }: {
  # Not compatible with Meson's default -O0.
  hardeningDisable = hardeningDisable ++ [ "fortify" ];
}))
