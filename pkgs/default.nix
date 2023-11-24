# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ ... } @ args:

let
  config = import ../lib/config.nix args;
  pkgs = import ./overlaid.nix ({ elaboratedConfig = config; } // args);

  inherit (pkgs.lib)
    cleanSource cleanSourceWith hasSuffix makeScope optionalAttrs;

  scope = self: let pkgs = self.callPackage ({ pkgs }: pkgs) {}; in {
    inherit config;

    callSpectrumPackage =
      path: (import path { inherit (self) callPackage; }).override;

    lseek = self.callSpectrumPackage ../tools/lseek {};
    rootfs = self.callSpectrumPackage ../host/rootfs {};
    start-vm = self.callSpectrumPackage ../host/start-vm {};

    # Packages from the overlay, so it's possible to build them from
    # the CLI easily.
    inherit (pkgs) cloud-hypervisor foot;

    pkgsStatic = makeScope pkgs.pkgsStatic.newScope scope;

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
