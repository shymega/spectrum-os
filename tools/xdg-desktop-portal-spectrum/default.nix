# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2024 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ src
, lib, stdenv, llvmPackages, llvmPackages_19, meson, ninja, pkg-config, dbus
}:

stdenv.mkDerivation (finalAttrs: {
  name = "xdg-desktop-portal-spectrum";

  src = lib.fileset.toSource {
    root = ../..;
    fileset = lib.fileset.intersection src ./.;
  };
  sourceRoot = "source/tools/xdg-desktop-portal-spectrum";

  mesonFlags = [
    "-Dhostfsrootdir=/run/virtiofs/virtiofs0"
  ];

  nativeBuildInputs = [ meson ninja pkg-config ];
  buildInputs = [ dbus ];

  passthru.tests = {
    clang-tidy = finalAttrs.finalPackage.overrideAttrs (
      { src, nativeBuildInputs ? [], ... }:
      {
        src = lib.fileset.toSource {
          root = ../..;
          fileset = lib.fileset.union (lib.fileset.fromSource src) ../../.clang-tidy;
        };

        nativeBuildInputs =
          assert lib.versionOlder llvmPackages.release_version "19";
          nativeBuildInputs ++ [ llvmPackages_19.clang-tools ];

        buildPhase = ''
          clang-tidy --warnings-as-errors='*' ../*.c
          touch $out
          exit 0
        '';
      }
    );
  };

  meta = with lib; {
    description = "XDG Desktop Portal implementation for Spectrum VMs";
    license = licenses.eupl12;
    maintainers = with maintainers; [ qyliss ];
    platforms = platforms.linux;
  };
})
) (_: {})
