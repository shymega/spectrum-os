# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

# Generated by scripts/update-nixpkgs.sh.

import (builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/c38df14dc75dc173ffdbf2ab838806057ef531ee.tar.gz";
  sha256 = "041mlanfsrrz2vyhcbg8zrxg4f35kp2fz34lwbg3hxv3c6xl0d4f";
})
