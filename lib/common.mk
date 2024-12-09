# SPDX-License-Identifier: EUPL-1.2+
# SPDX-FileCopyrightText: 2021, 2023 Alyssa Ross <hi@alyssa.is>

BACKGROUND = background
CPIO = cpio
CPIOFLAGS = --reproducible -R +0:+0 -H newc
CROSVM = crosvm
CROSVM_DEVICE_GPU = $(CROSVM) device gpu
CROSVM_RUN = $(CROSVM) run
GDB = gdb
MCOPY = mcopy
MKFS_FAT = mkfs.fat
MMD = mmd
S6_IPCSERVER_SOCKETBINDER = s6-ipcserver-socketbinder
TAR = tar
TRUNCATE = truncate
VERITYSETUP = veritysetup
VIRTIOFSD = virtiofsd
