# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix (
{ config, run ? ../../vm/app/mg.nix, ... }:

with config.pkgs;

(import ./. { inherit config; }).overrideAttrs (
{ passthru ? {}, nativeBuildInputs ? [], ... }:

{
  nativeBuildInputs = nativeBuildInputs ++ [
    # Both QEMU and virtiofsd come with a virtiofsd executable,
    # so we have to list virtiofsd first.
    virtiofsd

    cloud-hypervisor execline jq qemu_kvm reuse s6
  ];

  KERNEL = "${passthru.kernel.dev}/vmlinux";

  runDef = import run { inherit config; };
  shellHook = ''
    export RUN_IMG="$(printf "%s\n" "$runDef"/blk/run.img)"
  '';
}))
