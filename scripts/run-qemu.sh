#!/bin/sh -ue
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: EUPL-1.2+

# This script wraps around QEMU to paper over platform differences,
# which can't be handled portably in Make language.

machine=virt

if [ "${ARCH:="$(uname -m)"}" = x86_64 ]; then
	append="console=ttyS0${append:+ $append}"
	machine=q35
fi

i=0
while [ $i -lt $# ]; do
	arg="$1"
	shift

	if [ "$arg" = -append ]; then
		append="${append:+$append }$1"
		shift
		continue
	fi

	set -- "$@" "$arg"

	i=$((i + 1))
done

set -x
exec ${QEMU_SYSTEM:-qemu-system-$ARCH} \
	-accel kvm \
	-machine "$machine" \
	${append:+-append "$append"} \
	"$@"
