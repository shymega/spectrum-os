# SPDX-FileCopyrightText: 2022 Unikie
# SPDX-FileCopyrightText: 2023-2024 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

import ../../lib/overlay-package.nix [ "cloud-hypervisor" ] ({ final, super }:

super.cloud-hypervisor.overrideAttrs (
  { patches ? [], postUnpack ? "", postPatch ? "", ... }:
  {
    cargoDeps = final.rustPlatform.importCargoLock {
      lockFile = ./Cargo.lock;
      outputHashes = {
        "acpi_tables-0.1.0" = "sha256-ReIibUCFiLVq6AFqFupue/3BEQUJoImCLKaUBSVpdl4=";
        "micro_http-0.1.0" = "sha256-yIgcoEfc7eeS1+bijzkifaBxVNHa71Y+Vn79owMaKvM=";
        "mshv-bindings-0.3.0" = "sha256-IqmFB4nyENsfEPqiSYv52sL4LDiv+rCabTiIxE1MWZ0=";
        "vfio-bindings-0.4.0" = "sha256-ie/RcYbojLCGJkc6Yl97iUhOxnYk8/DO7JKlhMtT/6w=";
        "vfio_user-0.1.0" = "sha256-jScCwZEqoWYGBBKjoxB6xXOltX1/5h4Jgpcy5RzzTtg=";
        "vm-fdt-0.3.0" = "sha256-9PywgSnSL+8gT6lcl9t6w7X4fEINa+db+H1vWS+gDOI=";
      };
    };

    vhost = final.fetchFromGitHub {
      name = "vhost";
      owner = "rust-vmm";
      repo = "vhost";
      rev = "vhost-user-backend-v0.16.0";
      hash = "sha256-ol1QacoMD8E85uaNrCr7Vy92XjZfQCB9FbZsAEvq2fM=";
    };

    patches = patches ++ [
      ./0001-build-use-local-vhost.patch
      ./0002-virtio-devices-add-a-GPU-device.patch
    ];

    vhostPatches = [
      vhost/0001-vhost_user-add-get_size-to-MsgHeader.patch
      vhost/0002-vhost-fix-receiving-reply-payloads.patch
      vhost/0003-vhost_user-add-shared-memory-region-support.patch
      vhost/0004-vhost_user-add-protocol-flag-for-shmem.patch
    ];

    postUnpack = postUnpack + ''
      unpackFile $vhost
      chmod -R +w vhost
    '';

    postPatch = postPatch + ''
      pushd ../vhost
      for patch in $vhostPatches; do
          echo applying patch $patch
          patch -p1 < $patch
      done
      popd
    '';
  })
)
