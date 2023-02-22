# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>

{ config ? import ../../nix/eval-config.nix {} }:

let
  inherit (config) pkgs;

  extfs = pkgs.pkgsStatic.callPackage ./extfs.nix {
    inherit config;
  };
  rootfs = import ../rootfs { inherit config; };
  initramfs = import ./. { inherit config rootfs; };
in

with pkgs;

initramfs.overrideAttrs ({ nativeBuildInputs ? [], ... }: {
  nativeBuildInputs = nativeBuildInputs ++ [
    cryptsetup qemu_kvm tar2ext4 util-linux
  ];

  EXT_FS = extfs;
  KERNEL = "${rootfs.kernel}/${stdenv.hostPlatform.linux-kernel.target}";
  ROOT_FS = rootfs;
})
