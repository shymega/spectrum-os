# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021, 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/eval-config.nix ({ config, ... }:

let
  rootfs = import ./. { inherit config; };
in

with config.pkgs;

rootfs.overrideAttrs (
{ passthru ? {}, nativeBuildInputs ? [], ... }:

{
  nativeBuildInputs = nativeBuildInputs ++ [
    cryptsetup jq netcat qemu_kvm reuse util-linux
  ];

  EXT_FS = pkgsStatic.callPackage ../initramfs/extfs.nix { inherit config; };
  INITRAMFS = import ../initramfs { inherit config rootfs; };
  KERNEL = "${passthru.kernel}/${stdenv.hostPlatform.linux-kernel.target}";
  LINUX_SRC = srcOnly passthru.kernel;
  VMLINUX = "${passthru.kernel.dev}/vmlinux";
}))
