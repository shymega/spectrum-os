# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2021 Alyssa Ross <hi@alyssa.is>

{ lib, eos-installer, fetchurl, fetchpatch }:

let
  logo = fetchurl {
    url = "https://spectrum-os.org/git/www/plain/logo/logo140.png?id=5ac2d787b12e05a9ea91e94ca9373ced55d7371a";
    sha256 = "008dkzapyrkbva3ziyb2fa1annjwfk28q9kwj1bgblgrq6sxllxk";
  };
in

eos-installer.overrideAttrs ({ patches ? [], postPatch ? "", ... }: {
  patches = patches ++ [
    ./0001-gpt-disable-gpt-partition-attribute-55-check.patch
    ./0002-gpt-disable-partition-table-CRC-check.patch
    ./0003-install-remove-Endless-OS-ad.patch
    ./0004-finished-don-t-run-eos-diagnostics.patch
    ./0005-finished-promote-spectrum-not-the-Endless-forum.patch
  ];

  postPatch = postPatch + ''
    find . -type f -print0 | xargs -0 sed -i 's/Endless OS/Spectrum/g'
    cp ${logo} gnome-image-installer/pages/finished/endless_logo.png
  '';
})
