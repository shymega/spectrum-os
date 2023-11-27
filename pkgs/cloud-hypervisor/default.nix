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
      "acpi_tables-0.1.0" = "sha256-OGJX05yNwE7zZzATs8y0EZ714+lB+FgSia0TygRwWAU=";
      "kvm-bindings-0.6.0" = "sha256-wGdAuPwsgRIqx9dh0m+hC9A/Akz9qg9BM+p06Fi5ACM=";
      "kvm-ioctls-0.13.0" = "sha256-jHnFGwBWnAa2lRu4a5eRNy1Y26NX5MV8alJ86VR++QE=";
      "micro_http-0.1.0" = "sha256-wX35VsrO1vxQcGbOrP+yZm9vG0gcTZLe7gH7xuAa12w=";
      "mshv-bindings-0.1.1" = "sha256-8fEWawNeJ96CczFoJD3cqCsrROEvh8wJ4I0ForwzTJY=";
      "versionize_derive-0.1.4" = "sha256-oGuREJ5+FDs8ihmv99WmjIPpL2oPdOr4REk6+7cV/7o=";
      "vfio-bindings-0.4.0" = "sha256-hGhfOE9q9sf/tzPuaAHOca+JKCutcm1Myu1Tt9spaIQ=";
      "vfio_user-0.1.0" = "sha256-fAqvy3YTDKXQqtJR+R2nBCWIYe89zTwtbgvJfPLqs1Q=";
      "vm-fdt-0.2.0" = "sha256-lKW4ZUraHomSDyxgNlD5qTaBTZqM0Fwhhh/08yhrjyE=";
    };
  };

  vhost = final.fetchFromGitHub {
    name = "vhost";
    owner = "rust-vmm";
    repo = "vhost";
    rev = "vhost-user-backend-v0.10.1";
    hash = "sha256-pq545s7sqE0GFFkEkAvKwFKLuRArNThmRFqEYS3nNVo=";
  };

  cargoPatches = super.cloud-hypervisor.cargoPatches or [] ++ [
    ./0001-build-use-local-vhost.patch
    ./0002-virtio-devices-add-a-GPU-device.patch
  ];

  vhostPatches = [
    vhost/0001-vhost-fix-receiving-reply-payloads.patch
    vhost/0002-vhost_user-add-shared-memory-region-support.patch
    vhost/0003-vhost-user-add-protocol-flag-for-shmem.patch
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
