# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2023 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/eval-config.nix (

{ config, src
, lseek ? import ../../tools/lseek { inherit config; }
, ...
}:

let
  inherit (config) pkgs;
in

pkgs.pkgsStatic.callPackage (

{ lib, stdenvNoCC, nixos, runCommand, writeReferencesToFile, erofs-utils, s6-rc
, busybox, cloud-hypervisor, cryptsetup, execline, e2fsprogs, jq, kmod
, mdevd, s6, s6-linux-init, socat, util-linuxMinimal, virtiofsd, xorg
}:

let
  inherit (lib) concatMapStringsSep;
  inherit (nixosAllHardware.config.hardware) firmware;

  start-vm = import ../start-vm {
    config = config // { pkgs = pkgs.pkgsStatic; };
  };

  pkgsGui = pkgs.pkgsMusl.extend (final: super: {
    systemd = final.libudev-zero;
    systemdMinimal = final.libudev-zero;

    colord = super.colord.overrideAttrs ({ mesonFlags ? [], ... }: {
      mesonFlags = mesonFlags ++ [
        "-Dsystemd=false"
        "-Dudev_rules=false"
      ];
    });

    polkit = super.polkit.override {
      useSystemd = false;
    };

    seatd = super.seatd.override {
      systemdSupport = false;
    };

    weston = super.weston.overrideAttrs ({ mesonFlags ? [], ... }: {
      mesonFlags = mesonFlags ++ [
        "-Dsystemd=false"
      ];
    });
  });

  foot = pkgsGui.foot.override { allowPgo = false; };

  packages = [
    cloud-hypervisor e2fsprogs execline jq kmod mdevd s6 s6-linux-init s6-rc
    socat start-vm virtiofsd

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
        CONFIG_RMMOD n
      '';
    })
  ] ++ (with pkgsGui; [ foot westonLite ]);

  nixosAllHardware = nixos ({ modulesPath, ... }: {
    imports = [ (modulesPath + "/profiles/all-hardware.nix") ];
  });

  kernel = pkgs.linux_latest;

  appvm = import ../../img/app {
    inherit config;
    inherit (foot) terminfo;
  };

  # Packages that should be fully linked into /usr,
  # (not just their bin/* files).
  usrPackages = [ appvm pkgsGui.mesa.drivers pkgsGui.dejavu_fonts ];

  packagesSysroot = runCommand "packages-sysroot" {
    nativeBuildInputs = [ xorg.lndir ];
  } ''
    mkdir -p $out/lib $out/usr/bin
    ln -s ${concatMapStringsSep " " (p: "${p}/bin/*") packages} $out/usr/bin

    for pkg in ${lib.escapeShellArgs usrPackages}; do
        lndir -silent "$pkg" "$out/usr"
    done

    ln -s ${kernel}/lib/modules ${firmware}/lib/firmware $out/lib

    # TODO: this is a hack and we should just build the util-linux
    # programs we want.
    # https://lore.kernel.org/util-linux/87zgrl6ufb.fsf@alyssa.is/
    ln -s ${util-linuxMinimal}/bin/{findfs,lsblk} $out/usr/bin
  '';
in

stdenvNoCC.mkDerivation {
  name = "spectrum-rootfs";

  inherit src;
  sourceRoot = "source/host/rootfs";

  nativeBuildInputs = [ erofs-utils lseek s6-rc ];

  MODULES_ALIAS = "${kernel}/lib/modules/${kernel.modDirVersion}/modules.alias";
  MODULES_ORDER = "${kernel}/lib/modules/${kernel.modDirVersion}/modules.order";

  PACKAGES = [ packagesSysroot "/" ];

  shellHook = ''
    PACKAGES+=" $(sed p ${writeReferencesToFile packagesSysroot} | tr '\n' ' ')"
  '';

  preBuild = ''
    runHook shellHook
  '';

  makeFlags = [ "dest=$(out)" ];

  dontInstall = true;

  enableParallelBuilding = true;

  passthru = { inherit firmware kernel nixosAllHardware; };

  meta = with lib; {
    license = licenses.eupl12;
    platforms = platforms.linux;
  };
}
) {})
