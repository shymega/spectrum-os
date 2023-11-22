# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix ({ config, src, ... }:
config.pkgs.callPackage ({ runCommand }:

runCommand "spectrum-doc-anchors" {} ''
  ! grep --color=always -r xref:http ${src}
  touch $out
''
) { })
