# SPDX-License-Identifier: EUPL-1.2+
# SPDX-FileCopyrightText: 2021-2024 Alyssa Ross <hi@alyssa.is>

.POSIX:

include ../../lib/common.mk

DTBS ?= build/empty

dest = build/live.img

$(dest): ../../scripts/format-uuid.sh ../../scripts/make-gpt.sh ../../scripts/sfdisk-field.awk build/boot.fat build/rootfs.verity.superblock build/rootfs.verity.roothash $(ROOT_FS) $(EXT_FS)
	../../scripts/make-gpt.sh $@.tmp \
	    build/boot.fat:c12a7328-f81f-11d2-ba4b-00a0c93ec93b \
	    build/rootfs.verity.superblock:verity:$$(../../scripts/format-uuid.sh "$$(dd if=build/rootfs.verity.roothash bs=32 skip=1 count=1 status=none)") \
	    $(ROOT_FS):root:$$(../../scripts/format-uuid.sh "$$(head -c 32 build/rootfs.verity.roothash)") \
	    $(EXT_FS):9293e1ff-cee4-4658-88be-898ec863944f
	mv $@.tmp $@

build/empty:
	mkdir -p $@

# Each device tree is a PE section, and there can only be a maximum of
# 96 PE sections.  To work around this and consider every device tree
# provided by the kernel for auto-loading, split them across as many
# UKI addons (each of which is its own PE binary) as required.
# https://github.com/systemd/systemd/issues/35943
build/spectrum.efi.extra.d: $(DTBS)
	rm -rf $@
	mkdir -p $@
	i=0; find $(DTBS) -name '*.dtb' | xargs -rn 92 | while read -r dtbs; do \
	    i=$$((i + 1)) ;\
	    printf "[UKI]\nDeviceTreeAuto=%s\n" "$$dtbs" | $(UKIFY) build \
	        --output $@/dtbs$$i.addon.efi \
	        --config /dev/stdin ;\
	done

build/spectrum.efi: build/rootfs.verity.roothash $(KERNEL) $(INITRAMFS)
	$(UKIFY) build \
	    --output $@ \
	    --linux $(KERNEL) \
	    --initrd $(INITRAMFS) \
	    --os-release $$'NAME="Spectrum"\n' \
	    --cmdline "ro intel_iommu=on roothash=$$(cat build/rootfs.verity.roothash)"

build/boot.fat: $(SYSTEMD_BOOT_EFI) build/spectrum.efi build/spectrum.efi.extra.d
	$(TRUNCATE) -s 440401920 $@
	$(MKFS_FAT) $@
	$(MMD) -i $@ ::/EFI ::/EFI/BOOT ::/EFI/Linux
	$(MCOPY) -i $@ build/spectrum.efi ::/EFI/Linux
	$(MCOPY) -i $@ build/spectrum.efi.extra.d ::/EFI/Linux
	$(MCOPY) -i $@ $(SYSTEMD_BOOT_EFI) ::/EFI/BOOT/$(EFINAME)

# veritysetup format produces two files, but Make only (portably)
# supports one output per rule, so we combine the two outputs then
# define two more rules to separate them again.
build/rootfs.verity: $(ROOT_FS)
	mkdir -p build
	$(VERITYSETUP) format $(ROOT_FS) build/rootfs.verity.superblock.tmp \
	    | awk -F ':[[:blank:]]*' '$$1 == "Root hash" {print $$2; exit}' \
	    > build/rootfs.verity.roothash.tmp
	cat build/rootfs.verity.roothash.tmp build/rootfs.verity.superblock.tmp \
	    > $@
	rm build/rootfs.verity.roothash.tmp build/rootfs.verity.superblock.tmp
build/rootfs.verity.roothash: build/rootfs.verity
	head -n 1 build/rootfs.verity > $@
build/rootfs.verity.superblock: build/rootfs.verity
	tail -n +2 build/rootfs.verity > $@

clean:
	rm -rf build
.PHONY: clean

run: $(dest)
	@../../scripts/run-qemu.sh -m 4G \
	    -machine virtualization=on \
	    -cpu max \
	    -device virtio-keyboard \
	    -device virtio-mouse \
	    -device virtio-gpu \
	    -parallel none \
	    -vga none \
	    -device qemu-xhci \
	    -device usb-storage,drive=drive1,removable=true \
	    -drive file=$(OVMF_CODE),format=raw,if=pflash,readonly=true \
	    -drive file=$(dest),id=drive1,format=raw,if=none,readonly=true
.PHONY: run
