# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/call-package.nix (
{ callSpectrumPackage, runCommand, bozohttpd, wget }:

runCommand "spectrum-doc-links" {
  doc = callSpectrumPackage ../../Documentation {};
  nativeBuildInputs = [ bozohttpd wget ];
} ''
  mkdir root
  ln -s $doc root/doc
  httpd -bI 4000 root
  wget -r -nv --delete-after --no-parent --retry-connrefused http://localhost:4000/doc/
  touch $out
''
) (_: {})
