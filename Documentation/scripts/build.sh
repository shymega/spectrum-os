#!/bin/sh -e
# SPDX-FileCopyrightText: 2022 Unikie
# SPDX-License-Identifier: EUPL-1.2+

cd "$(dirname "$0")/.."

if [ ! -w . ] && [ ! -w .jekyll-cache ]; then
	set -- --disable-disk-cache "$@"
fi

find . '(' '!' -path ./_site -o -prune ')' \
	-a -name '*.drawio' \
	-exec drawio -xf svg '{}' ';'
jekyll build -b /doc "$@"
