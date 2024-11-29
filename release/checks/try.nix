# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023-2024 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix (
{ callSpectrumPackage, lib, nixosTest, path }:

lib.fix (self: nixosTest ({ pkgs, stdenv, mtools, ... }:

let
  live = callSpectrumPackage ../live {};

  inherit (import (path + /nixos/lib/qemu-common.nix) { inherit lib pkgs; })
    qemuBinary qemuSerialDevice;
in {
  name = "try-spectrum-test";
  nodes = {};

  testScript = ''
    import shlex
    import subprocess

    conf = subprocess.run([
      "${mtools}/bin/mcopy",
      "-i",
      "${live}@@1M",
      "::loader/entries/spectrum.conf",
      "-",
    ], stdout=subprocess.PIPE)
    conf.check_returncode()

    cmdline = None
    for line in conf.stdout.decode('utf-8').splitlines():
      key, value = line.split(' ', 1)
      if key == 'options':
        cmdline = value
        break

    flags = "${qemuBinary self.config.qemu.package} " + " ".join(map(shlex.quote, [
      "-m", "512",
      "-kernel", "${live.rootfs.kernel}/${stdenv.hostPlatform.linux-kernel.target}",
      "-initrd", "${live.initramfs}",
      "-device", "qemu-xhci",
      "-device", "usb-storage,drive=drive1,removable=true",
      "-drive", "file=${live},id=drive1,format=raw,if=none,readonly=on",
      "-append", f"console=${qemuSerialDevice} panic=-1 {cmdline}",
    ]))

    machine = create_machine(flags)

    machine.start()
    machine.wait_for_console_text("EXT4-fs \\(sda4\\): mounted filesystem")
    machine.crash()
  '';
}))) (_: {})
