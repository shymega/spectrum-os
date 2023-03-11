# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Unikie

import ../../lib/eval-config.nix ({ config, ... }:
config.pkgs.callPackage ({ runCommand, ruby, wget }:

runCommand "spectrum-doc-links" {
  doc = import ../../Documentation { inherit config; };
  nativeBuildInputs = [ ruby wget ];
} ''
  mkdir root
  ln -s $doc root/doc
  ruby -run -e httpd -- --port 4000 root &
  wget -r -nv --delete-after --no-parent --retry-connrefused http://localhost:4000/doc/
  touch $out
''
) { })
