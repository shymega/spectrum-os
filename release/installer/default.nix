# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ extraConfig, nixos, writeClosure }:

let
  inherit (nixos {
    imports = [ ./configuration.nix extraConfig ];
  }) config;
in

{
  kernel = "${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}";

  initramfs = "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";

  kernelParams = toString ([
    "init=${config.system.build.toplevel}/init"
  ] ++ config.boot.kernelParams);

  store = writeClosure [ config.system.build.toplevel ];
}) (_: { extraConfig = {}; })
