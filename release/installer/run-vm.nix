# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ callSpectrumPackage, lib, coreutils, qemu_kvm, stdenv, writeShellScript }:

let
  inherit (builtins) storeDir;
  inherit (lib) makeBinPath escapeShellArg;

  eosimages = callSpectrumPackage ../combined/eosimages.nix {};

  installer = callSpectrumPackage ./. {
    extraConfig = {
      boot.initrd.availableKernelModules = [ "9p" "9pnet_virtio" ];

      fileSystems.${storeDir} = {
        fsType = "9p";
        device = "store";
      };
    };
  };
in

writeShellScript "run-spectrum-installer-vm.sh" ''
  export PATH=${makeBinPath [ coreutils qemu_kvm ]}
  img="$(mktemp spectrum-installer-target.XXXXXXXXXX.img)"
  truncate -s 20G "$img"
  exec 3<>"$img"
  rm -f "$img"
  exec qemu-kvm -cpu host -m 4G -machine q35 \
    -display gtk,gl=on \
    -device virtio-vga-gl \
    -virtfs local,mount_tag=store,path=/nix/store,security_model=none,readonly=true \
    -drive file=${qemu_kvm}/share/qemu/edk2-${stdenv.hostPlatform.qemuArch}-code.fd,format=raw,if=pflash,readonly=true \
    -drive file=${eosimages},format=raw,if=virtio,readonly=true \
    -drive file=/proc/self/fd/3,format=raw,if=virtio \
    -kernel ${installer.kernel} \
    -initrd ${installer.initramfs} \
    -append ${escapeShellArg installer.kernelParams}
'') (_: {})
