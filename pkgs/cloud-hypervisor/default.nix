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
        "acpi_tables-0.1.0" = "sha256-a6ojB2XVeH+YzzXRle0agg+ljn0Jsgyaf6TJZAGt8sQ=";
        "micro_http-0.1.0" = "sha256-yIgcoEfc7eeS1+bijzkifaBxVNHa71Y+Vn79owMaKvM=";
        "mshv-bindings-0.2.0" = "sha256-NYViItbjt1Q2G4yO3j37naHe9EJ+llkjrNt6w4zoiW8=";
        "vfio-bindings-0.4.0" = "sha256-mzdYH23CVWm7fvu4+1cFHlPhkUjh7+JlU/ScoXaDNgA=";
        "vfio_user-0.1.0" = "sha256-LJ84k9pMkSAaWkuaUd+2LnPXnNgrP5LdbPOc1Yjz5xA=";
        "vm-fdt-0.3.0" = "sha256-9PywgSnSL+8gT6lcl9t6w7X4fEINa+db+H1vWS+gDOI=";
      };
    };

    vhost = final.fetchFromGitHub {
      name = "vhost";
      owner = "rust-vmm";
      repo = "vhost";
      rev = "vhost-user-backend-v0.15.0";
      hash = "sha256-KPaGoh2xaKuMA+fNU82SwL51TTTIx0ZkumxN1R7maIA=";
    };

    patches = patches ++ [
      ./0001-build-use-local-vhost.patch
      ./0002-virtio-devices-add-a-GPU-device.patch
    ];

    vhostPatches = [
      vhost/0001-vhost-fix-receiving-reply-payloads.patch
      vhost/0002-vhost_user-add-shared-memory-region-support.patch
      vhost/0003-vhost_user-add-protocol-flag-for-shmem.patch
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
