# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

let
  makeUnoverridable = attrs:
    removeAttrs attrs [ "override" "overrideDerivation" ];
in

package: overrides: { pkgs ? import ../pkgs args, ... } @ args:
pkgs.callPackage package (makeUnoverridable (pkgs.callPackage overrides {}))
