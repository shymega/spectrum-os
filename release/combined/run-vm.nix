# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021, 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ callSpectrumPackage, lib, writeShellScript, coreutils, qemu_kvm, stdenv }:

let
  image = callSpectrumPackage ./. {};
in

writeShellScript "run-spectrum-installer-vm.sh" ''
  export PATH=${lib.makeBinPath [ coreutils qemu_kvm ]}
  img="$(mktemp spectrum-installer-target.XXXXXXXXXX.img)"
  truncate -s 20G "$img"
  exec 3<>"$img"
  rm -f "$img"
  exec qemu-kvm -cpu host -m 4G -machine q35,kernel-irqchip=split \
    -display gtk,gl=on \
    -device intel-iommu,intremap=on \
    -device virtio-vga-gl \
    -device qemu-xhci \
    -device usb-storage,drive=drive1,removable=true \
    -drive file=${qemu_kvm}/share/qemu/edk2-${stdenv.hostPlatform.qemuArch}-code.fd,format=raw,if=pflash,readonly=true \
    -drive file=${image},id=drive1,format=raw,if=none,readonly=true \
    -drive file=/proc/self/fd/3,format=raw,if=virtio
'') (_: {})
