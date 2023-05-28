#!/bin/sh -eu
#
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: EUPL-1.2+
#
# FIXME: It would be nice to replace this script with a program that
#        didn't have to redundantly copy everything so it's all in a
#        single directory structure, and could generate an EROFS image
#        based on source:dest mappings directly.

ex_usage() {
	echo "Usage: make-erofs.sh [options]... -- img [source dest]..." >&2
	exit 1
}

opt_count=0
while [ $# -gt $opt_count ]; do
	arg1="$1"
	shift

        if [ -z "${img-}" ]; then
		set -- "$@" "$arg1"
		opt_count=$((opt_count + 1))

		if [ "$arg1" = -- ]; then
			img="$1"
			shift

			if [ $(($# % 2)) -eq 0 ]; then
				ex_usage
			fi

			root="$(mktemp -d -- "$img.tmp.XXXXXXXXXX")"
			trap 'chmod -R +w -- "$root" && rm -rf -- "$root"' EXIT
		fi

		continue
	fi

	arg2="$1"
	shift

	printf "%s" "$arg1"
	if [ "${arg1#/}" != "${arg2#/}" ]; then
		printf " -> %s" "$arg2"
	fi
	echo

	parent="$root/$(dirname "$arg2")"
	chmod -R +w -- "$root"
	mkdir -p -- "$parent"
	cp -RT -- "$arg1" "$root/$arg2"
done

if [ -z "${img-}" ]; then
	ex_usage
fi

mkfs.erofs "$@" "$img" "$root"
