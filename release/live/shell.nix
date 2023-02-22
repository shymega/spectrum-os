# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix ({ config, ... }:

with config.pkgs;

(import ./. { inherit config; }).overrideAttrs (
  { nativeBuildInputs ? [], ... }:
  {
    nativeBuildInputs = nativeBuildInputs ++ [ qemu_kvm ];

    OVMF_CODE = "${qemu_kvm}/share/qemu/edk2-${stdenv.hostPlatform.qemuArch}-code.fd";
  }
))
