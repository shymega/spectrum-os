# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021, 2023-2024 Alyssa Ross <hi@alyssa.is>

import ../../../lib/call-package.nix (
{ callSpectrumPackage, srcOnly
, cloud-hypervisor, crosvm, execline, jq, iproute2, qemu_kvm, reuse
}:

(callSpectrumPackage ./. {}).overrideAttrs (
{ nativeBuildInputs ? [], env ? {}, passthru ? {}, ... }:

{
  nativeBuildInputs = nativeBuildInputs ++ [
    cloud-hypervisor crosvm execline jq iproute2 qemu_kvm reuse
  ];

  env = env // {
    LINUX_SRC = srcOnly passthru.kernel;
    VMLINUX = "${passthru.kernel.dev}/vmlinux";
  };
})) (_: {})
