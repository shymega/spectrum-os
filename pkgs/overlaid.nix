# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ config ? null
, elaboratedConfig ? import ../lib/config.nix args
} @ args:

elaboratedConfig.pkgsFun (elaboratedConfig.pkgsArgs // {
  overlays = elaboratedConfig.pkgsArgs.overlays or [] ++ [
    (import ./overlay.nix)
  ];
})
