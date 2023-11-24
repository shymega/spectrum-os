# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

let
  makeUnoverridable = attrs:
    removeAttrs attrs [ "override" "overrideDerivation" ];
in

package: overrides:
{ callPackage ? (import ../pkgs args).callPackage, ... } @ args:
callPackage package (makeUnoverridable (callPackage overrides {}))
