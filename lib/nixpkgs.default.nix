# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

# Generated by scripts/update-nixpkgs.sh.

import (builtins.fetchTarball {
  url = "https://spectrum-os.org/git/nixpkgs/snapshot/nixpkgs-47ab9dadb6032a6aeab75463d3b87ff707414323.tar.gz";
  sha256 = "0qbjrya5qyb8jwv1kwihmfw9w11rjdm1h7w0z7yvkhdnl7w1i530";
})
