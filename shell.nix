# SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

import lib/call-package.nix ({ mkShell, b4, reuse }:

mkShell {
  nativeBuildInputs = [ b4 reuse ];
}) (_: {})
