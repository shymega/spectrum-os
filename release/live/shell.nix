# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ callSpectrumPackage, stdenv, qemu_kvm }:

(callSpectrumPackage ./. {}).overrideAttrs (
  { nativeBuildInputs ? [], ... }:
  {
    nativeBuildInputs = nativeBuildInputs ++ [ qemu_kvm ];

    OVMF_CODE = "${qemu_kvm}/share/qemu/edk2-${stdenv.hostPlatform.qemuArch}-code.fd";
  }
)) (_: {})
