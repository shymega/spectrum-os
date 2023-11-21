# SPDX-License-Identifier: EUPL-1.2+
# SPDX-FileCopyrightText: 2021-2023 Alyssa Ross <hi@alyssa.is>

include ../../../lib/common.mk

prefix = build/svc

VMM = qemu

HOST_BUILD_FILES = \
	build/host/data/netvm/blk/root.img \
	build/host/data/netvm/vmlinux

# We produce a directory, but that doesn't play nice with Make,
# because it won't know to update if some file in the directory is
# changed, or a file is created or removed in a subdirectory.  Using
# the whole directory could also end up including files that aren't
# intended to be part of the input, like temporary editor files or
# .license files.  So for all these reasons, only explicitly listed
# files are included in the build result.
$(prefix): $(HOST_BUILD_FILES)
	rm -rf $@
	mkdir -p $@

	tar -c $(HOST_BUILD_FILES) | tar -C $@ -x --strip-components 2

build/host/data/netvm/vmlinux: $(KERNEL)
	mkdir -p $$(dirname $@)
	cp $(KERNEL) $@

build/host/data/netvm/blk/root.img: ../../../scripts/make-gpt.sh ../../../scripts/sfdisk-field.awk build/rootfs.erofs
	mkdir -p $$(dirname $@)
	../../../scripts/make-gpt.sh $@.tmp \
	    build/rootfs.erofs:4f68bce3-e8cd-4db1-96e7-fbcaf984b709:ea21da27-0391-48da-9235-9d2ab2ca7844:root
	mv $@.tmp $@

VM_FILES = \
	etc/dbus-1/system.conf \
	etc/fstab \
	etc/init \
	etc/mdev.conf \
	etc/mdev/iface \
	etc/nftables.conf \
	etc/passwd \
	etc/s6-linux-init/run-image/service/getty-hvc0/run \
	etc/s6-linux-init/scripts/rc.init \
	etc/sysctl.conf
VM_DIRS = dev etc/s6-linux-init/env run proc sys var/lib/connman

# These are separate because they need to be included, but putting
# them as make dependencies would confuse make.
VM_LINKS = bin var/run

VM_BUILD_FILES = build/etc/s6-rc

build/empty:
	mkdir -p $@

build/rootfs.erofs: ../../../scripts/make-erofs.sh $(VM_FILES) $(VM_BUILD_FILES) build/empty
	../../../scripts/make-erofs.sh -- $@ $(PACKAGES) \
	    $$(for file in $(VM_FILES) $(VM_LINKS); do printf '%s %s ' $$file $$file; done) \
	    $$(for file in $(VM_BUILD_FILES); do printf '%s %s ' $$file $${file#build/}; done) \
	    $$(printf 'build/empty %s ' $(VM_DIRS))

VM_S6_RC_FILES = \
	etc/s6-rc/connman/dependencies \
	etc/s6-rc/connman/run \
	etc/s6-rc/connman/type \
	etc/s6-rc/dbus/notification-fd \
	etc/s6-rc/dbus/run \
	etc/s6-rc/dbus/type \
	etc/s6-rc/mdevd-coldplug/dependencies \
	etc/s6-rc/mdevd-coldplug/type \
	etc/s6-rc/mdevd-coldplug/up \
	etc/s6-rc/mdevd/notification-fd \
	etc/s6-rc/mdevd/run \
	etc/s6-rc/mdevd/type \
	etc/s6-rc/nftables/type \
	etc/s6-rc/nftables/up \
	etc/s6-rc/ok-all/contents \
	etc/s6-rc/ok-all/type \
	etc/s6-rc/sysctl/type \
	etc/s6-rc/sysctl/up

build/etc/s6-rc: $(VM_S6_RC_FILES)
	mkdir -p $$(dirname $@)
	rm -rf $@

	dir=$$(mktemp -d) && \
	    tar -c $(VM_S6_RC_FILES) | tar -C $$dir -x --strip-components 2 && \
	    s6-rc-compile $@ $$dir; \
	    exit=$$?; rm -r $$dir; exit $$exit

debug:
	$(GDB) -q \
	    -ex 'set substitute-path .. $(LINUX_SRC)' \
	    -ex 'target remote build/gdb.sock' \
	    $(VMLINUX)
.PHONY: debug

run-qemu: build/host/data/netvm/blk/root.img
	@../../../scripts/run-qemu.sh -m 128 -cpu host -kernel $(KERNEL) -vga none \
	    -drive file=build/host/data/netvm/blk/root.img,if=virtio,format=raw,readonly=on \
	    -append nokaslr \
	    -gdb unix:build/gdb.sock,server,nowait \
	    -netdev user,id=net0 \
	    -device e1000e,netdev=net0 \
	    -netdev user,id=net1 \
	    -device virtio-net,netdev=net1,mac=0A:B3:EC:80:00:00 \
	    -chardev vc,id=virtiocon0 \
	    -device virtio-serial-pci \
	    -device virtconsole,chardev=virtiocon0
.PHONY: run-qemu

run-cloud-hypervisor: build/host/data/netvm/blk/root.img
	rm -f build/vmm.sock
	@../../../scripts/run-cloud-hypervisor.sh \
	    --api-socket path=build/vmm.sock \
	    --memory size=128M \
	    --disk path=build/host/data/netvm/blk/root.img,readonly=on \
	    --net tap=tap0 \
	    --net tap=tap1,mac=0A:B3:EC:80:00:00 \
	    --kernel $(KERNEL) \
	    --console tty \
	    --serial pty
.PHONY: run-cloud-hypervisor

run-crosvm: build/host/data/netvm/blk/root.img
	$(CROSVM_RUN) \
	    --disk build/host/data/netvm/blk/root.img \
	    --net tap-name=tap0 \
	    --net tap-name=tap1,mac=0A:B3:EC:80:00:00 \
	    --serial type=file,hardware=serial,path=build/crosvm.log \
	    --serial type=stdout,hardware=virtio-console,stdin=true \
	    $(KERNEL)
.PHONY: run-crosvm

run: run-$(VMM)
.PHONY: run

clean:
	rm -rf build
.PHONY: clean
