# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2023 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/call-package.nix (
{ callSpectrumPackage, lseek, src, pkgsMusl, pkgsStatic, linux_latest }:
pkgsStatic.callPackage (

{ start-vmm
, lib, stdenvNoCC, nixos, runCommand, writeClosure, erofs-utils, s6-rc, busybox
, cloud-hypervisor, cryptsetup, dbus, execline, e2fsprogs, jq, kmod, mdevd, s6
, s6-linux-init, socat, util-linuxMinimal, virtiofsd, xorg
}:

let
  inherit (lib) concatMapStringsSep optionalAttrs systems;
  inherit (nixosAllHardware.config.hardware) firmware;

  pkgsGui = pkgsMusl.extend (
    final: super:
    (optionalAttrs (systems.equals pkgsMusl.stdenv.hostPlatform super.stdenv.hostPlatform) {
      libgudev = super.libgudev.overrideAttrs ({ ... }: {
        # Tests use umockdev, which is not compatible with libudev-zero.
        doCheck = false;
      });

      systemd = final.libudev-zero;
      systemdLibs = final.libudev-zero;
      systemdMinimal = final.libudev-zero;

      seatd = super.seatd.override {
        systemdSupport = false;
      };

      weston = super.weston.overrideAttrs ({ mesonFlags ? [], ... }: {
        mesonFlags = mesonFlags ++ [
          "-Dsystemd=false"
        ];
      });
    })
  );

  foot = pkgsGui.foot.override { allowPgo = false; };

  packages = [
    cloud-hypervisor dbus e2fsprogs execline jq kmod mdevd
    s6 s6-linux-init s6-rc socat start-vmm virtiofsd

    (cryptsetup.override {
      programs = {
        cryptsetup = false;
        cryptsetup-reencrypt = false;
        integritysetup = false;
      };
    })

    (busybox.override {
      extraConfig = ''
        CONFIG_CHATTR n
        CONFIG_DEPMOD n
        CONFIG_FINDFS n
        CONFIG_INIT n
        CONFIG_INSMOD n
        CONFIG_LSATTR n
        CONFIG_LSMOD n
        CONFIG_MKE2FS n
        CONFIG_MKFS_EXT2 n
        CONFIG_MODINFO n
        CONFIG_MODPROBE n
        CONFIG_MOUNT n
        CONFIG_RMMOD n
      '';
    })
  ] ++ (with pkgsGui; [ crosvm foot westonLite ]);

  nixosAllHardware = nixos ({ modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/all-hardware.nix") ];

    system.stateVersion = lib.trivial.release;
  });

  kernel = linux_latest;

  appvm = callSpectrumPackage ../../img/app { inherit (foot) terminfo; };

  # Packages that should be fully linked into /usr,
  # (not just their bin/* files).
  usrPackages = [
    appvm kernel firmware pkgsGui.mesa.drivers pkgsGui.dejavu_fonts
  ];

  packagesSysroot = runCommand "packages-sysroot" {
    nativeBuildInputs = [ xorg.lndir ];
  } ''
    mkdir -p $out/usr/bin $out/usr/share/dbus-1
    ln -s ${concatMapStringsSep " " (p: "${p}/bin/*") packages} $out/usr/bin
    ln -st $out/usr/share/dbus-1 \
        ${dbus}/share/dbus-1/session.conf

    for pkg in ${lib.escapeShellArgs usrPackages}; do
        lndir -ignorelinks -silent "$pkg" "$out/usr"
    done

    # TODO: this is a hack and we should just build the util-linux
    # programs we want.
    # https://lore.kernel.org/util-linux/87zgrl6ufb.fsf@alyssa.is/
    ln -s ${util-linuxMinimal}/bin/{findfs,lsblk,mount} $out/usr/bin
  '';
in

stdenvNoCC.mkDerivation {
  name = "spectrum-rootfs";

  src = lib.fileset.toSource {
    root = ../..;
    fileset = src;
  };
  sourceRoot = "source/host/rootfs";

  nativeBuildInputs = [ erofs-utils lseek s6-rc ];

  MODULES_ALIAS = "${kernel}/lib/modules/${kernel.modDirVersion}/modules.alias";
  MODULES_ORDER = "${kernel}/lib/modules/${kernel.modDirVersion}/modules.order";

  PACKAGES = [ packagesSysroot "/" ];

  shellHook = ''
    PACKAGES+=" $(sed p ${writeClosure [ packagesSysroot ]} | tr '\n' ' ')"
  '';

  preBuild = ''
    runHook shellHook
  '';

  makeFlags = [ "dest=$(out)" ];

  dontInstall = true;

  enableParallelBuilding = true;

  passthru = { inherit appvm firmware kernel nixosAllHardware; };

  meta = with lib; {
    license = licenses.eupl12;
    platforms = platforms.linux;
  };
}
) {}) (_: {})
