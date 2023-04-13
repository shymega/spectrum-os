# SPDX-License-Identifier: EUPL-1.2+
# SPDX-FileCopyrightText: 2021, 2023 Alyssa Ross <hi@alyssa.is>

.POSIX:

# qemu-kvm is non-standard, but is present in at least Fedora and
# Nixpkgs.  If you don't have qemu-kvm, you'll need to set e.g.
# QEMU_KVM = qemu-system-x86_64 -enable-kvm.
QEMU_KVM = qemu-kvm

BACKGROUND = background
CPIO = cpio
CPIOFLAGS = --reproducible -R +0:+0 -H newc
MCOPY = mcopy
MKFS_FAT = mkfs.fat
MMD = mmd
OBJCOPY = objcopy
S6_IPCSERVER_SOCKETBINDER = s6-ipcserver-socketbinder
TAR = tar
TAR2EXT4 = tar2ext4
TRUNCATE = truncate
VERITYSETUP = veritysetup
VIRTIOFSD = virtiofsd

.SUFFIXES: .ext4 .tar
.tar.ext4:
	$(TAR2EXT4) -i $< -o $@
