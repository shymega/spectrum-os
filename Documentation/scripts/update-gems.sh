#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bundler bundix

# SPDX-FileCopyrightText: 2022 Unikie
# SPDX-License-Identifier: EUPL-1.2+

# shellcheck shell=bash

set -euo pipefail

cd "$(dirname "$0")/.."
bundle lock --update
bundix -l
