# SPDX-FileCopyrightText: 2024 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

import ../../lib/call-package.nix (
{ src, lib, rustPlatform }:

rustPlatform.buildRustPackage {
  name = "xdg-desktop-portal-spectrum-host";

  src = lib.fileset.toSource {
    root = ../..;
    fileset = lib.fileset.intersection src ./.;
  };
  sourceRoot = "source/tools/xdg-desktop-portal-spectrum-host";

  cargoLock.lockFile = ./Cargo.lock;
}) (_: {})
