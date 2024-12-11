# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ callSpectrumPackage, nixosTest }:

let
  live = callSpectrumPackage ../live {};
in

nixosTest ({ stdenv, mtools, ... }: {
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

    flags = " ".join(map(shlex.quote, [
      "qemu-kvm",
      "-m", "512",
      "-kernel", "${live.rootfs.kernel}/${stdenv.hostPlatform.linux-kernel.target}",
      "-initrd", "${live.initramfs}",
      "-device", "qemu-xhci",
      "-device", "usb-storage,drive=drive1,removable=true",
      "-drive", "file=${live},id=drive1,format=raw,if=none,readonly=on",
      "-append", f"console=ttyS0 panic=-1 {cmdline}",
    ]))

    machine = create_machine(flags)

    machine.start()
    machine.wait_for_console_text("EXT4-fs \\(sda4\\): mounted filesystem")
    machine.crash()
  '';
})) (_: {})
