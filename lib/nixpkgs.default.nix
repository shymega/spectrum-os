# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

# Generated by scripts/update-nixpkgs.sh.

import (builtins.fetchTarball {
  url = "https://github.com/NixOS/nixpkgs/archive/c374d94f1536013ca8e92341b540eba4c22f9c62.tar.gz";
  sha256 = "1vc8bzz04ni7l15a9yd1x7jn0bw2b6rszg1krp6bcxyj3910pwb7";
})
