# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021-2023 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2021 Yureka <yuka@yuka.dev>
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/call-package.nix (
{ callSpectrumPackage
, lib, runCommand, stdenv, substituteAll, writeClosure
, dosfstools, grub2_efi, jq, libfaketime, mtools, squashfs-tools-ng
, systemdMinimal, util-linux
}:

let
  inherit (builtins) storeDir;
  inherit (lib) removePrefix toUpper;

  eosimages = callSpectrumPackage ./eosimages.nix {};

  installerPartUuid = "6e23b026-9f1e-479d-8a58-a0cda382e1ce";
  installer = callSpectrumPackage ../installer {
    extraConfig = {
      boot.initrd.availableKernelModules = [ "squashfs" ];

      fileSystems.${storeDir} = {
        device = "/dev/disk/by-partuuid/${installerPartUuid}";
      };
    };
  };

  rootfs = runCommand "installer.img" {
    nativeBuildInputs = [ squashfs-tools-ng ];
    __structuredAttrs = true;
    unsafeDiscardReferences = { out = true; };
  } ''
    sed 's,^${storeDir}/,,' ${writeClosure [ installer.store ]} |
        tar -C ${storeDir} -c --verbatim-files-from -T - \
            --owner 0 --group 0 | tar2sqfs $out
  '';

  efiArch = stdenv.hostPlatform.efiArch;

  grub = grub2_efi;

  grubCfg = substituteAll {
    src = ./grub.cfg.in;

    linux = removePrefix storeDir installer.kernel;
    initrd = removePrefix storeDir installer.initramfs;
    inherit (installer) kernelParams;
  };

  esp = runCommand "esp.img" {
    nativeBuildInputs = [ grub libfaketime dosfstools mtools ];

    env = {
      grubTargetDir = "${grub}/lib/grub/${grub.grubTarget}";
      # Definition copied from util/grub-install-common.c.
      # Last checked: GRUB 2.06
      pkglib_DATA = lib.escapeShellArgs [
        "efiemu32.o" "efiemu64.o" "moddep.lst" "command.lst" "fs.lst"
        "partmap.lst" "parttool.lst" "video.lst" "crypto.lst" "terminal.lst"
        "modinfo.sh"
      ];
    };

    __structuredAttrs = true;

    unsafeDiscardReferences = { out = true; };

    passthru = { inherit grubCfg; };
  } ''
    truncate -s 15M $out
    faketime "1970-01-01 00:00:00" mkfs.vfat -i 0x2178694e -n EFI $out
    mmd -i $out ::/EFI ::/EFI/BOOT \
        ::/grub ::/grub/${grub.grubTarget} ::/grub/fonts

    mcopy -i $out ${grubCfg} ::/grub/grub.cfg
    mcopy -i $out $grubTargetDir/*.mod ::/grub/${grub.grubTarget}
    for file in $pkglib_DATA; do
        path="$grubTargetDir/$file"
        ! [ -e "$path" ] || mcopy -i $out "$path" ::/grub/${grub.grubTarget}
    done
    mcopy -i $out ${grub}/share/grub/unicode.pf2 ::/grub/fonts

    grub-mkimage -o grub${efiArch}.efi -p "(hd0,gpt1)/grub" -O ${grub.grubTarget} part_gpt fat
    mcopy -i $out grub${efiArch}.efi ::/EFI/BOOT/BOOT${toUpper efiArch}.EFI

    fsck.vfat -n $out
  '';
in

runCommand "spectrum-installer" {
  nativeBuildInputs = [ grub jq util-linux systemdMinimal ];
  __structuredAttrs = true;
  unsafeDiscardReferences = { out = true; };
  passthru = { inherit eosimages esp installer rootfs; };
} ''
  blockSize() {
      wc -c "$1" | awk '{printf "%d\n", ($1 + 511) / 512}'
  }

  fillPartition() {
      read start size < <(sfdisk -J "$1" | jq -r --argjson index "$2" \
          '.partitiontable.partitions[$index] | "\(.start) \(.size)"')
      dd if="$3" of="$1" seek="$start" count="$size" conv=notrunc
  }

  espSize="$(blockSize ${esp})"
  installerSize="$(blockSize ${rootfs})"
  eosimagesSize="$(blockSize ${eosimages})"

  truncate -s $(((3 * 2048 + $espSize + $installerSize + $eosimagesSize) * 512)) $out
  sfdisk --no-reread --no-tell-kernel $out <<EOF
  label: gpt
  size=$espSize, type=U
  size=$installerSize, type=L, uuid=${installerPartUuid}
  size=$eosimagesSize, type=56a3bbc3-aefa-43d9-a64d-7b3fd59bbc4e
  EOF

  fillPartition $out 0 ${esp}
  fillPartition $out 1 ${rootfs}
  fillPartition $out 2 ${eosimages}
'') (_: {})
