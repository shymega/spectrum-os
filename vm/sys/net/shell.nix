# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021 Alyssa Ross <hi@alyssa.is>

import ../../../nix/eval-config.nix ({ config, ... }: with config.pkgs;

(import ./. { inherit config; }).overrideAttrs (
{ passthru ? {}, nativeBuildInputs ? [], ... }:

{
  nativeBuildInputs = nativeBuildInputs ++ [ cloud-hypervisor jq qemu_kvm reuse ];

  KERNEL = "${passthru.kernel.dev}/vmlinux";
}))
