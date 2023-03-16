# SPDX-License-Identifier: EUPL-1.2+
# SPDX-FileCopyrightText: 2021-2023 Alyssa Ross <hi@alyssa.is>

include ../../lib/common.mk

prefix = build/host
imgdir = $(prefix)/img

VMM = qemu

HOST_BUILD_FILES = \
	$(imgdir)/appvm/blk/root.img \
	$(imgdir)/appvm/vmlinux

all: $(HOST_BUILD_FILES)
.PHONY: all

$(imgdir)/appvm/vmlinux: $(VMLINUX)
	mkdir -p $$(dirname $@)
	cp $(VMLINUX) $@

$(imgdir)/appvm/blk/root.img: ../../scripts/make-gpt.sh ../../scripts/sfdisk-field.awk build/rootfs.ext4
	mkdir -p $$(dirname $@)
	../../scripts/make-gpt.sh $@.tmp \
	    build/rootfs.ext4:4f68bce3-e8cd-4db1-96e7-fbcaf984b709:5460386f-2203-4911-8694-91400125c604:root
	mv $@.tmp $@

VM_FILES = \
	etc/fstab \
	etc/init \
	etc/mdev.conf \
	etc/mdev/iface \
	etc/mdev/listen \
	etc/mdev/virtiofs \
	etc/mdev/wait \
	etc/passwd \
	etc/resolv.conf \
	etc/s6-linux-init/scripts/rc.init
VM_DIRS = dev run proc sys \
	etc/s6-linux-init/env \
	etc/s6-linux-init/run-image/ext \
	etc/s6-linux-init/run-image/service

# These are separate because they need to be included, but putting
# them as make dependencies would confuse make.
VM_LINKS = bin etc/ssl/certs/ca-certificates.crt

VM_BUILD_FILES = build/etc/s6-rc

build/empty:
	mkdir -p $@

build/rootfs.tar: build/empty $(PACKAGES_TAR) $(VM_FILES) $(VM_BUILD_FILES)
	cp --no-preserve=mode -f $(PACKAGES_TAR) $@
	tar $(TARFLAGS) --append -f $@ $(VM_FILES) $(VM_LINKS)
	echo $(VM_BUILD_FILES) | cut -d/ -f2 | \
	    tar $(TARFLAGS) --append -f $@ -C build -T -
	for m in $(VM_DIRS); do \
	    tar $(TARFLAGS) --append -hf $@ --xform="s,.*,$$m," build/empty ; \
	done

VM_S6_RC_FILES = \
	etc/s6-rc/app/run \
	etc/s6-rc/app/type \
	etc/s6-rc/mdevd-coldplug/dependencies \
	etc/s6-rc/mdevd-coldplug/type \
	etc/s6-rc/mdevd-coldplug/up \
	etc/s6-rc/mdevd/notification-fd \
	etc/s6-rc/mdevd/run \
	etc/s6-rc/mdevd/type \
	etc/s6-rc/ok-all/contents \
	etc/s6-rc/ok-all/type

build/etc/s6-rc: $(VM_S6_RC_FILES)
	mkdir -p $$(dirname $@)
	rm -rf $@

	dir=$$(mktemp -d) && \
	    tar -c $(VM_S6_RC_FILES) | tar -C $$dir -x --strip-components 2 && \
	    s6-rc-compile $@ $$dir; \
	    exit=$$?; rm -r $$dir; exit $$exit

start-virtiofsd:
	mkdir -p build
	$(S6_IPCSERVER_SOCKETBINDER) -B build/virtiofsd.sock \
	    $(BACKGROUND) $(VIRTIOFSD) --fd 0 --shared-dir . ""
.PHONY: start-virtiofsd

run-qemu: $(imgdir)/appvm/blk/root.img start-virtiofsd
	$(QEMU_KVM) -m 128 -cpu host -machine q35,kernel=$(KERNEL) -vga none \
	    -drive file=$(imgdir)/appvm/blk/root.img,if=virtio,format=raw,readonly=on \
	    -drive file=$(RUN_IMG),if=virtio,format=raw,readonly=on \
	    -append "console=ttyS0 root=PARTLABEL=root" \
	    -netdev user,id=net0 \
	    -device virtio-net,netdev=net0,mac=0A:B3:EC:00:00:00 \
	    -chardev socket,id=virtiofsd,path=build/virtiofsd.sock \
	    -device vhost-user-fs-pci,chardev=virtiofsd,tag=virtiofs0 \
	    -object memory-backend-memfd,id=mem,size=128M,share=on \
	    -numa node,memdev=mem \
	    -chardev vc,id=virtiocon0 \
	    -device virtio-serial-pci \
	    -device virtconsole,chardev=virtiocon0
.PHONY: run-qemu

run-cloud-hypervisor: $(imgdir)/appvm/blk/root.img start-virtiofsd
	rm -f build/vmm.sock
	$(CLOUD_HYPERVISOR) \
	    --api-socket path=build/vmm.sock \
	    --memory size=128M,shared=on \
	    --disk path=$(imgdir)/appvm/blk/root.img,readonly=on \
	           path=$(RUN_IMG),readonly=on \
	    --fs tag=virtiofs0,socket=build/virtiofsd.sock \
	    --kernel $(KERNEL) \
	    --cmdline "console=ttyS0 root=PARTLABEL=root" \
	    --console tty \
	    --serial pty
.PHONY: run-cloud-hypervisor

run: run-$(VMM)
.PHONY: run

clean:
	rm -rf build
.PHONY: clean
