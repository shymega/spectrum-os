# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

let
  customConfigPath = builtins.tryEval <spectrum-config>;
in

{ config ?
  if customConfigPath.success then import customConfigPath.value
  else if builtins.pathExists ../config.nix then import ../config.nix
  else {}
}:

let
  default = import ../lib/config.default.nix;

  callConfig = config: if builtins.typeOf config == "lambda" then config {
    inherit default;
  } else config;

  fullConfig = default // callConfig config;

  pkgs = fullConfig.pkgsFun fullConfig.pkgsArgs;

  inherit (pkgs.lib)
    cleanSource cleanSourceWith hasSuffix makeScope optionalAttrs;

  scope = self: {
    config = fullConfig;

    callSpectrumPackage =
      path: (import path { inherit (self) callPackage; }).override;

    lseek = self.callSpectrumPackage ../tools/lseek {};
    rootfs = self.callSpectrumPackage ../host/rootfs {};
    start-vm = self.callSpectrumPackage ../host/start-vm {};

    pkgsStatic = makeScope
      (self.callPackage ({ pkgs }: pkgs) {}).pkgsStatic.newScope scope;
    
    src = cleanSourceWith {
      filter = path: type:
        path != toString ../Documentation/_site &&
        path != toString ../Documentation/.jekyll-cache &&
        path != toString ../Documentation/diagrams/stack.svg &&
        (type == "regular" -> !hasSuffix ".nix" path) &&
        (type == "directory" -> builtins.baseNameOf path != "build");
      src = cleanSource ../.;
    };
  };
in

pkgs.makeScopeWithSplicing' {
  otherSplices = {
    selfBuildBuild = makeScope pkgs.pkgsBuildBuild.newScope scope;
    selfBuildHost = makeScope pkgs.pkgsBuildHost.newScope scope;
    selfBuildTarget = makeScope pkgs.pkgsBuildTarget.newScope scope;
    selfHostHost = makeScope pkgs.pkgsHostHost.newScope scope;
    selfTargetTarget = optionalAttrs (pkgs.pkgsTargetTarget ? newScope)
      (makeScope pkgs.pkgsTargetTarget.newScope scope);
  };
  f = scope;
}
