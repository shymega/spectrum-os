# SPDX-FileCopyrightText: 2024 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

import ../../lib/overlay-package.nix [ "dbus" ] ({ final, super }:

super.dbus.overrideAttrs ({ configureFlags ? [], patches ? [], ... }: {
  patches = patches ++ [
    # https://gitlab.freedesktop.org/dbus/dbus/-/merge_requests/200
    ./0001-doc-add-vsock-address-format-to-the-spec.patch
    ./0002-build-sys-add-enable-vsock-option.patch
    ./0003-unix-add-vsock-support-to-_dbus_append_address_from_.patch
    ./0004-dbus-add-_dbus_listen_vsock.patch
    ./0005-dbus-add-vsock-server-support.patch
    ./0006-dbus-add-_dbus_connect_vsock.patch
    ./0007-dbus-add-vsock-client-support.patch
    ./0008-test-add-simple-loopback-vsock-test.patch
    ./0009-vsock-add-allow-CIDs.-on-listenable-address.patch
  ];

  configureFlags = configureFlags ++ [
    "--enable-vsock"
  ];

  separateDebugInfo = true;
}))
