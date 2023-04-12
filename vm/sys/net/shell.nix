# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021 Alyssa Ross <hi@alyssa.is>

import ../../../lib/eval-config.nix ({ config, ... }: with config.pkgs;

(import ./. { inherit config; }).overrideAttrs (
{ passthru ? {}, nativeBuildInputs ? [], ... }:

{
  nativeBuildInputs = nativeBuildInputs ++ [ cloud-hypervisor jq qemu_kvm reuse ];
}))
