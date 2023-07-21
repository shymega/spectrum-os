# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

{ pkgs ? import <nixpkgs> {}

# Paths that are present in the base image that will start this VM's
# run script, and don't so need to be duplicated in the extension
# partition's store.
, basePaths ? builtins.toFile "null" ""
}:

pkgs.pkgsStatic.callPackage (

{ lib, runCommand, writeReferencesToFile, erofs-utils }:

{ run, providers ? {}, sharedDirs ? {} }:

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
  mkdir -p "$out"/{blk,providers,shared-dirs}

  ${../scripts/make-erofs.sh} -L ext -- "$out/blk/run.img" ${run} run \
      ${pkgs.pkgsMusl.mesa.drivers} / \
      $(comm -23 <(sort ${writeReferencesToFile run} ${writeReferencesToFile pkgs.pkgsMusl.mesa.drivers}) \
          <(sort ${writeReferencesToFile basePaths}) | sed p)

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
