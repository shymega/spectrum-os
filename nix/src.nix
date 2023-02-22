# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

{ lib }:

lib.cleanSourceWith {
  filter = path: type:
    path != toString ../Documentation/_site &&
    path != toString ../Documentation/.jekyll-cache &&
    path != toString ../Documentation/diagrams/stack.svg &&
    (type == "file" -> !lib.hasSuffix ".nix" path) &&
    (type == "directory" -> builtins.baseNameOf path != "build");
  src = lib.cleanSource ../.;
}
