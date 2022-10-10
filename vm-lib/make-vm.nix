# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

{ pkgs ? import <nixpkgs> {}

# Paths that are present in the base image that will start this VM's
# run script, and don't so need to be duplicated in the extension
# partition's store.
, basePaths ? builtins.toFile "null" ""
}:

pkgs.pkgsStatic.callPackage (

{ lib, runCommand, writeReferencesToFile, e2fsprogs, tar2ext4 }:

{ run, providers ? {}, sharedDirs ? {} }:

let
  inherit (lib)
    any attrValues concatLists concatStrings concatStringsSep hasInfix
    mapAttrsToList;
in

assert !(any (hasInfix "\n") (concatLists (attrValues providers)));

runCommand "spectrum-vm" {
  nativeBuildInputs = [ e2fsprogs tar2ext4 ];

  providerDirs = concatStrings (concatLists
    (mapAttrsToList (kind: map (vm: "${kind}/${vm}\n")) providers));
  passAsFile = [ "providerDirs" ];
} ''
  mkdir -p "$out"/{blk,providers,shared-dirs}

  mkdir root
  cd root
  ln -s ${run} run
  comm -23 <(sort ${writeReferencesToFile run}) \
      <(sort ${writeReferencesToFile basePaths}) |
      tar -cf ../run.tar --verbatim-files-from -T - run
  tar2ext4 -i ../run.tar -o "$out/blk/run.img"
  e2label "$out/blk/run.img" ext

  pushd "$out"

  pushd providers
  xargs -rd '\n' dirname -- < "$providerDirsPath" | xargs -rd '\n' mkdir -p --
  xargs -rd '\n' touch -- < "$providerDirsPath"
  popd

  pushd shared-dirs
  ${concatStringsSep "\n" (mapAttrsToList (key: { path }: ''
    mkdir ${lib.escapeShellArg key}
    ln -s ${lib.escapeShellArgs [ path "${key}/dir" ]}
  '') sharedDirs)}
  popd

  popd

  ln -s /usr/img/appvm/blk/root.img "$out/blk"
  ln -s /usr/img/appvm/vmlinux "$out"
''
) {}
