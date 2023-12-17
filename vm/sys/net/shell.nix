# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021, 2023 Alyssa Ross <hi@alyssa.is>

import ../../../lib/call-package.nix (
{ callSpectrumPackage, srcOnly
, cloud-hypervisor, crosvm, execline, jq, iproute2, qemu_kvm, reuse
}:

(callSpectrumPackage ./. {}).overrideAttrs (
{ nativeBuildInputs ? [], passthru ? {}, ... }:

{
  nativeBuildInputs = nativeBuildInputs ++ [
    cloud-hypervisor crosvm execline jq iproute2 qemu_kvm reuse
  ];

  LINUX_SRC = srcOnly passthru.kernel;
  VMLINUX = "${passthru.kernel.dev}/vmlinux";
})) (_: {})
