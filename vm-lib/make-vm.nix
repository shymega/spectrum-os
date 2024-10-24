# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022, 2024 Alyssa Ross <hi@alyssa.is>
# SPDX-FileCopyrightText: 2022 Unikie

{ pkgs ? import <nixpkgs> {}

# Paths that are present in the base image that will start this VM's
# run script, and don't so need to be duplicated in the extension
# partition's store.
, basePaths ? builtins.toFile "null" ""
}:

pkgs.pkgsStatic.callPackage (

{ lib, runCommand, writeClosure, erofs-utils }:

{ run, type, providers ? {}, sharedDirs ? {} }:

let
  inherit (lib)
    any attrValues concatLists concatStrings concatStringsSep hasInfix
    mapAttrsToList;
in

assert !(any (hasInfix "\n") (concatLists (attrValues providers)));

runCommand "spectrum-vm" {
  nativeBuildInputs = [ erofs-utils ];

  providerDirs = concatStrings (concatLists
    (mapAttrsToList (kind: map (vm: "${kind}/${vm}\n")) providers));
  passAsFile = [ "providerDirs" ];
} ''
  mkdir -p $out/{blk,fs,providers}
  pushd "$out"

  echo ${type} > fs/type
  ln -s ${run} fs/run
  mkdir -p fs${builtins.storeDir}
  comm -23 <(sort ${writeClosure [ run ]}) \
      <(sort ${writeClosure [ basePaths ]}) |
      xargs -rd '\n' cp -rvt fs${builtins.storeDir}

  pushd providers
  xargs -rd '\n' dirname -- < "$providerDirsPath" | xargs -rd '\n' mkdir -p --
  xargs -rd '\n' touch -- < "$providerDirsPath"
  popd

  popd

  ln -s /usr/img/appvm/blk/root.img "$out/blk"
  ln -s /usr/img/appvm/vmlinux "$out"
''
) {}
