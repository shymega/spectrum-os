# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/eval-config.nix ({ config, src, ... }:
config.pkgs.callPackage (

{ stdenvNoCC, cryptsetup, dosfstools, jq, mtools, util-linux, stdenv
, systemd }:

let
  inherit (config) pkgs;
  inherit (pkgs.lib) hasSuffix toUpper;

  extfs = pkgs.pkgsStatic.callPackage ../../host/initramfs/extfs.nix {
    inherit config;
  };
  rootfs = import ../../host/rootfs { inherit config; };
  initramfs = import ../../host/initramfs { inherit config rootfs; };
  efiArch = stdenv.hostPlatform.efiArch;
in

stdenvNoCC.mkDerivation {
  name = "spectrum-live.img";

  inherit src;
  sourceRoot = "source/release/live";

  nativeBuildInputs = [ cryptsetup dosfstools jq mtools util-linux ];

  EXT_FS = extfs;
  INITRAMFS = initramfs;
  KERNEL = "${rootfs.kernel}/${stdenv.hostPlatform.linux-kernel.target}";
  ROOT_FS = rootfs;
  SYSTEMD_BOOT_EFI = "${systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
  EFINAME = "BOOT${toUpper efiArch}.EFI";

  buildFlags = [ "build/live.img" ];

  installPhase = ''
    runHook preInstall
    mv build/live.img $out
    runHook postInstall
  '';

  enableParallelBuilding = true;

  passthru = { inherit rootfs; };
}
) {})
