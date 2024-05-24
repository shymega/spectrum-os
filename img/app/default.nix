# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2024 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ lseek, src, terminfo, pkgsMusl, pkgsStatic }:
pkgsStatic.callPackage (

{ lib, stdenvNoCC, runCommand, writeClosure
, erofs-utils, jq, s6-rc, util-linux
, busybox, cacert, dbus, execline, kmod, linux_latest, mdevd, s6, s6-linux-init
, xdg-desktop-portal-spectrum
}:

let
  inherit (lib) concatMapStringsSep;

  packages = [
    dbus execline kmod mdevd s6 s6-linux-init s6-rc xdg-desktop-portal-spectrum

    (busybox.override {
      extraConfig = ''
        CONFIG_DEPMOD n
        CONFIG_INSMOD n
        CONFIG_LSMOD n
        CONFIG_MODINFO n
        CONFIG_MODPROBE n
        CONFIG_RMMOD n
      '';
    })
  ];

  packagesSysroot = runCommand "packages-sysroot" {
    inherit packages;
    passAsFile = [ "packages" ];
  } ''
    mkdir -p \
        $out/usr/bin \
        $out/usr/share/dbus-1/services \
        $out/usr/share/xdg-desktop-portal/portals
    ln -s ${concatMapStringsSep " " (p: "${p}/bin/*") packages} $out/usr/bin
    ln -st $out/usr/share/dbus-1/services \
        ${pkgsMusl.xdg-desktop-portal}/share/dbus-1/services/*.service \
        ${pkgsMusl.xdg-desktop-portal-gtk}/share/dbus-1/services/*.service \
        ${xdg-desktop-portal-spectrum}/share/dbus-1/services/*.service
    ln -st $out/usr/share/xdg-desktop-portal/portals \
        ${pkgsMusl.xdg-desktop-portal-gtk}/share/xdg-desktop-portal/portals/*.portal \
        ${xdg-desktop-portal-spectrum}/share/xdg-desktop-portal/portals/*.portal
    ln -s ${kernel}/lib "$out"
    ln -s ${terminfo}/share/terminfo $out/usr/share
    ln -s ${cacert}/etc/ssl $out/usr/share
  '';

  kernelTarget =
    if stdenvNoCC.hostPlatform.isx86 then
      # vmlinux.bin is the stripped version of vmlinux.
      # Confusingly, compressed/vmlinux.bin is the stripped version of
      # the top-level vmlinux target, while the top-level vmlinux.bin
      # is the stripped version of compressed/vmlinux.  So we use
      # compressed/vmlinux.bin, since we want a stripped version of
      # the kernel that *hasn't* been built to be compressed.  Weird!
      "compressed/vmlinux.bin"
    else
      stdenvNoCC.hostPlatform.linux-kernel.target;

  kernel = (linux_latest.override {
    structuredExtraConfig = with lib.kernel; {
      DRM_FBDEV_EMULATION = lib.mkForce no;
      EROFS_FS = yes;
      FONTS = lib.mkForce unset;
      FONT_8x8 = lib.mkForce unset;
      FONT_TER16x32 = lib.mkForce unset;
      FRAMEBUFFER_CONSOLE = lib.mkForce unset;
      FRAMEBUFFER_CONSOLE_DEFERRED_TAKEOVER = lib.mkForce unset;
      FRAMEBUFFER_CONSOLE_DETECT_PRIMARY = lib.mkForce unset;
      FRAMEBUFFER_CONSOLE_ROTATION = lib.mkForce unset;
      RC_CORE = lib.mkForce unset;
      VIRTIO = yes;
      VIRTIO_BLK = yes;
      VIRTIO_CONSOLE = yes;
      VIRTIO_PCI = yes;
      VT = no;
    };
  }).overrideAttrs ({ installFlags ? [], ... }: {
    installFlags = installFlags ++ [
      "KBUILD_IMAGE=$(boot)/${kernelTarget}"
    ];
  });
in

stdenvNoCC.mkDerivation {
  name = "spectrum-appvm";

  src = lib.fileset.toSource {
    root = ../..;
    fileset = lib.fileset.intersection src (lib.fileset.unions [
      ./.
      ../../lib/common.mk
      ../../scripts/make-erofs.sh
      ../../scripts/make-gpt.sh
      ../../scripts/sfdisk-field.awk
    ]);
  };
  sourceRoot = "source/img/app";

  nativeBuildInputs = [ erofs-utils jq lseek s6-rc util-linux ];

  PACKAGES = [ packagesSysroot "/" ];
  KERNEL = "${kernel}/${baseNameOf kernelTarget}";

  shellHook = ''
    PACKAGES+=" $(sed p ${writeClosure [ packagesSysroot ]} | tr '\n' ' ')"
  '';

  preBuild = ''
    runHook shellHook
  '';

  makeFlags = [ "prefix=$(out)" ];

  dontInstall = true;

  enableParallelBuilding = true;

  passthru = { inherit kernel packagesSysroot; };

  meta = with lib; {
    license = licenses.eupl12;
    platforms = platforms.linux;
  };
}
) {}) ({ foot }: { inherit (foot) terminfo; })
