# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ src, runCommand }:

runCommand "spectrum-doc-anchors" {} ''
  ! grep --color=always -r xref:http ${src}
  touch $out
''
) (_: {})
