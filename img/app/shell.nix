# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2023 Alyssa Ross <hi@alyssa.is>

{ run ? ../../vm/app/foot.nix, ... } @ args:

import ../../lib/call-package.nix (
{ callSpectrumPackage, srcOnly
, cloud-hypervisor, crosvm, execline, jq, iproute2, qemu_kvm, reuse, s6
, virtiofsd
}:

(callSpectrumPackage ./. {}).overrideAttrs (
{ nativeBuildInputs ? [], shellHook ? "", passthru ? {}, ... }:

{
  nativeBuildInputs = nativeBuildInputs ++ [
    cloud-hypervisor crosvm execline jq iproute2 qemu_kvm reuse s6 virtiofsd
  ];

  runDef = callSpectrumPackage run {};
  shellHook = shellHook + ''
    export RUN_IMG="$(printf "%s\n" "$runDef"/blk/run.img)"
  '';

  LINUX_SRC = srcOnly passthru.kernel;
  VMLINUX = "${passthru.kernel.dev}/vmlinux";
})) (_: {}) (removeAttrs args [ "run" ])
