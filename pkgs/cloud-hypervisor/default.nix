# SPDX-FileCopyrightText: 2022 Unikie
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

import ../../lib/overlay-package.nix "cloud-hypervisor" ({ final, super }:

final.rustPlatform.buildRustPackage {
  inherit (super.cloud-hypervisor)
    pname version src separateDebugInfo nativeBuildInputs buildInputs
    propagatedBuildInputs OPENSSL_NO_VENDOR cargoTestFlags meta;

  cargoLock = {
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

  cargoPatches = super.cloud-hypervisor.cargoPatches or [] ++ [
    ./0001-build-use-local-vhost.patch
    ./0002-virtio-devices-add-a-GPU-device.patch
  ];

  vhostPatches = [
    vhost/0001-vhost-fix-receiving-reply-payloads.patch
    vhost/0002-vhost_user-add-shared-memory-region-support.patch
    vhost/0003-vhost_user-add-protocol-flag-for-shmem.patch
    vhost/0004-vhost_user-renumber-SHARED_MEMORY_REGIONS.patch
    vhost/0005-vmm_vhost-choose-new-ids-for-the-non-standard-messag.patch
  ];

  # Don't concatenate versions from super.cloud-hypervisor,
  # because we'll get the versions from buildRustPackage twice.
  postUnpack = ''
    unpackFile $vhost
    chmod -R +w vhost
  '';

  postPatch = ''
    pushd ../vhost
    for patch in $vhostPatches; do
        echo applying patch $patch
        patch -p1 < $patch
    done
    popd
  '';
})
