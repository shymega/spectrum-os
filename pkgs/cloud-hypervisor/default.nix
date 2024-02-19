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
      "acpi_tables-0.1.0" = "sha256-syDq+db1hTne6QoP0vMGUv4tB0J9arQG2Ea2hHW1k3M=";
      "igvm-0.1.0" = "sha256-l+Qyhdy3b8h8hPLHg5M0os8aSkjM55hAP5nqi0AGmjo=";
      "kvm-bindings-0.7.0" = "sha256-hXv5N3TTwGQaVxdQ/DTzLt+uwLxFnstJwNhxRD2K8TM=";
      "micro_http-0.1.0" = "sha256-gyeOop6AMXEIbLXhJMN/oYGGU8Un8Y0nFZc9ucCa0y4=";
      "mshv-bindings-0.1.1" = "sha256-yWvkpOcW3lV47s+rWnN4Bki8tt8CkiPVZ0I36nrWMi4=";
      "versionize_derive-0.1.6" = "sha256-eI9fM8WnEBZvskPhU67IWeN6QAPg2u5EBT+AOxfb/fY=";
      "vfio-bindings-0.4.0" = "sha256-Dk4T2dMzPZ+Aoq1YSXX2z1Nky8zvyDl7b+A8NH57Hkc=";
      "vfio_user-0.1.0" = "sha256-LJ84k9pMkSAaWkuaUd+2LnPXnNgrP5LdbPOc1Yjz5xA=";
      "vm-fdt-0.2.0" = "sha256-lKW4ZUraHomSDyxgNlD5qTaBTZqM0Fwhhh/08yhrjyE=";
    };
  };

  vhost = final.fetchFromGitHub {
    name = "vhost";
    owner = "rust-vmm";
    repo = "vhost";
    rev = "vhost-user-backend-v0.13.1";
    hash = "sha256-iF0VPrTEq9blT6hY0QyLcq64+ZNsiEv1EA3c7NoQLRE=";
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
