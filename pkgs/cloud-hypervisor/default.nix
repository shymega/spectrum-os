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
      "acpi_tables-0.1.0" = "sha256-FYjzwCSjuTUDCCQPC2ccDpwRRaG1eT5XgV/b8uSu8uc=";
      "igvm-0.1.0" = "sha256-l+Qyhdy3b8h8hPLHg5M0os8aSkjM55hAP5nqi0AGmjo=";
      "kvm-bindings-0.6.0" = "sha256-wGdAuPwsgRIqx9dh0m+hC9A/Akz9qg9BM+p06Fi5ACM=";
      "kvm-ioctls-0.13.0" = "sha256-jHnFGwBWnAa2lRu4a5eRNy1Y26NX5MV8alJ86VR++QE=";
      "micro_http-0.1.0" = "sha256-Ov75Gs+wSmsxOHJu024nWtOJp0cKpS8bkxJJGW6jiKw=";
      "mshv-bindings-0.1.1" = "sha256-4ADpLvi9hmHsMyGtqDQ2Msa3aMZmJsi4BPW7B5ZfAMw=";
      "versionize_derive-0.1.4" = "sha256-oGuREJ5+FDs8ihmv99WmjIPpL2oPdOr4REk6+7cV/7o=";
      "vfio-bindings-0.4.0" = "sha256-grOV+7W1tB4YDRAFbDNQp5nQ1WaivH+N+qHTIj4WA+E=";
      "vfio_user-0.1.0" = "sha256-Vi6dBu1mUwyWh7ryKDOBS6GeUD2sqqIrt/bth/LDW6s=";
      "vm-fdt-0.2.0" = "sha256-lKW4ZUraHomSDyxgNlD5qTaBTZqM0Fwhhh/08yhrjyE=";
    };
  };

  vhost = final.fetchFromGitHub {
    name = "vhost";
    owner = "rust-vmm";
    repo = "vhost";
    rev = "vhost-user-backend-v0.11.0";
    hash = "sha256-VLKlvyHUrMrwJALUP7OeVeHIogu8rfoP4sgyUMCIBzU=";
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
