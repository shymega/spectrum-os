# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

# This file is built to populate the binary cache.

import lib/eval-config.nix ({ config, ... }: {
  doc = import ./Documentation { inherit config; };

  checks = import release/checks { inherit config; };

  combined = import release/combined/run-vm.nix { inherit config; };
})
