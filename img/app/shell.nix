# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix (
{ config, run ? ../../vm/app/catgirl.nix, ... }:

with config.pkgs;

(import ./. { inherit config; }).overrideAttrs (
{ passthru ? {}, nativeBuildInputs ? [], ... }:

{
  nativeBuildInputs = nativeBuildInputs ++ [
    cloud-hypervisor jq qemu_kvm reuse
  ];

  KERNEL = "${passthru.kernel.dev}/vmlinux";

  runDef = import run { inherit config; };
  shellHook = ''
    export RUN_IMG="$(printf "%s\n" "$runDef"/blk/run.img)"
  '';
}))
