# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix ({ config, ... }:
config.pkgs.callPackage ({ runCommand }:

runCommand "spectrum-doc-anchors" {} ''
  cd ${(import ../../Documentation { inherit config; }).src}
  ! grep --color=always -r xref:http
  touch $out
''
) { })
