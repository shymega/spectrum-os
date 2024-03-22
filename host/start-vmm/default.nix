# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ src, lib, stdenv, fetchCrate, fetchurl, buildPackages
, meson, ninja, rustc, clippy, run-spectrum-vm
}:

let
  packageCache = [
    (fetchCrate {
      pname = "itoa";
      version = "1.0.10";
      unpack = false;
      hash = "sha256-saRtGhcdhlql+D+SaVdlyqBHqbTLriy/N9vWE6eT/Uw=";
    })
    (fetchurl {
      name = "miniserde-0.1.38.tar.gz";
      url = "https://github.com/dtolnay/miniserde/archive/0.1.38.tar.gz";
      hash = "sha256-QmT40OREY7i8T/Q9movk6gD6xsVhlejxnjFrj86d4TI=";
    })
    (fetchCrate {
      pname = "proc-macro2";
      version = "1.0.79";
      unpack = false;
      hash = "sha256-6DX/Ipj1chYI6xqYDsruGu8sEyv5XswCahG3vzwBwC4=";
    })
    (fetchCrate {
      pname = "quote";
      version = "1.0.35";
      unpack = false;
      hash = "sha256-KR7Jq179k0qvUDpkZsXVJRU10QjudHRyw5d8xazIaO8=";
    })
    (fetchCrate {
      pname = "ryu";
      version = "1.0.17";
      unpack = false;
      hash = "sha256-6GaXyRYBmoWIyZtfrDzq107AtLgZcHpoL9TSP6DOG6E=";
    })
    (fetchCrate {
      pname = "syn";
      version = "2.0.53";
      unpack = false;
      hash = "sha256-c4PNDkn/9La5DKVnC/0+nWpzOz+QxoZgWqfuyMSZYDI=";
    })
    (fetchCrate {
      pname = "unicode-ident";
      version = "1.0.12";
      unpack = false;
      hash = "sha256-M1S5rD+uH/Z1XLbbU2g622YWNPZ1V5Qt6k+s6+wP7ks=";
    })
  ];
in

stdenv.mkDerivation (finalAttrs: {
  name = "start-vmm";

  src = lib.fileset.toSource {
    root = ../..;
    fileset = lib.fileset.intersection src ./.;
  };
  sourceRoot = "source/host/start-vmm";

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ meson ninja rustc ];

  postPatch = lib.concatMapStringsSep "\n" (crate: ''
    mkdir -p subprojects/packagecache
    ln -s ${crate} subprojects/packagecache/${crate.name}
  '') packageCache;

  mesonFlags = [ "-Dtests=false" "-Dunwind=false" "-Dwerror=true" ];

  passthru.tests = {
    clippy = finalAttrs.finalPackage.overrideAttrs (
      { name, nativeBuildInputs ? [], ... }:
      {
        name = "${name}-clippy";
        nativeBuildInputs = nativeBuildInputs ++ [ clippy ];
        RUSTC = "clippy-driver";
        preConfigure = ''
          # It's not currently possible to enable warnings only for
          # non-subprojects without enumerating the subprojects.
          # https://github.com/mesonbuild/meson/issues/9398#issuecomment-954094750
          mesonFlagsArray+=(
              -Dproc-macro2:werror=false
              -Dproc-macro2:warning_level=0
              -Dsyn:werror=false
              -Dsyn:warning_level=0
          )
        '';
        postBuild = ''touch $out && exit 0'';
      }
    );

    run = run-spectrum-vm.override { start-vmm = finalAttrs.finalPackage; };

    tests = finalAttrs.finalPackage.overrideAttrs ({ name, ... }: {
      name = "${name}-tests";
      preConfigure = "";
      doCheck = true;
    });
  };

  meta = {
    mainProgram = "start-vmm";
  };
})
) (_: {})
