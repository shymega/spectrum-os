# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix (
{ config, run ? ../../vm/app/mg.nix, ... }:

with config.pkgs;

(import ./. { inherit config; }).overrideAttrs (
{ nativeBuildInputs ? [], shellHook ? "", passthru ? {}, ... }:

{
  nativeBuildInputs = nativeBuildInputs ++ [
    # Both QEMU and virtiofsd come with a virtiofsd executable,
    # so we have to list virtiofsd first.
    virtiofsd

    cloud-hypervisor crosvm execline jq qemu_kvm reuse s6
  ];

  runDef = import run { inherit config; };
  shellHook = shellHook + ''
    export RUN_IMG="$(printf "%s\n" "$runDef"/blk/run.img)"
  '';

  LINUX_SRC = srcOnly passthru.kernel;
  VMLINUX = "${passthru.kernel.dev}/vmlinux";
}))
