#!/bin/sh -ue
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: EUPL-1.2+

# This script wraps around cloud-hypervisor to paper over platform
# differences, which can't be handled portably in Make language.

if [ "${ARCH:="$(uname -m)"}" = x86_64 ]; then
	cmdline="console=ttyS0${cmdline:+ $cmdline}"
fi

i=0
while [ $i -lt $# ]; do
	arg="$1"
	shift

	if [ "$arg" = --cmdline ]; then
		cmdline="${cmdline:+$cmdline }$1"
		shift
		continue
	fi

	set -- "$@" "$arg"

	i=$((i + 1))
done

set -x
exec ${CLOUD_HYPERVISOR:-cloud-hypervisor} ${cmdline:+--cmdline "$cmdline"} "$@"
