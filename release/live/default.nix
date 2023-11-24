# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2023 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/call-package.nix (
{ callSpectrumPackage, lseek, rootfs, src, lib, pkgsStatic, stdenvNoCC
, cryptsetup, dosfstools, jq, mtools, util-linux, stdenv
, systemd
}:

let
  inherit (lib) toUpper;

  extfs = pkgsStatic.callPackage ../../host/initramfs/extfs.nix {
    inherit callSpectrumPackage;
  };
  initramfs = callSpectrumPackage ../../host/initramfs {};
  efiArch = stdenv.hostPlatform.efiArch;
in

stdenvNoCC.mkDerivation {
  name = "spectrum-live.img";

  inherit src;
  sourceRoot = "source/release/live";

  nativeBuildInputs = [ cryptsetup dosfstools jq lseek mtools util-linux ];

  EXT_FS = extfs;
  INITRAMFS = initramfs;
  KERNEL = "${rootfs.kernel}/${stdenv.hostPlatform.linux-kernel.target}";
  ROOT_FS = rootfs;
  SYSTEMD_BOOT_EFI = "${systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
  EFINAME = "BOOT${toUpper efiArch}.EFI";

  buildFlags = [ "dest=$(out)" ];

  dontInstall = true;

  enableParallelBuilding = true;

  passthru = { inherit initramfs rootfs; };
}
) (_: {})
