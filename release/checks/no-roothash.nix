# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/call-package.nix ({ callSpectrumPackage, rootfs, nixosTest }:

let
  initramfs = callSpectrumPackage ../../host/initramfs {};
in

nixosTest ({ stdenv, ... }: {
  name = "spectrum-test-initramfs-no-roothash";
  nodes = {};

  testScript = ''
    import shlex

    flags = " ".join(map(shlex.quote, [
      "qemu-kvm",
      "-m", "512",
      "-kernel", "${rootfs.kernel}/${stdenv.hostPlatform.linux-kernel.target}",
      "-initrd", "${initramfs}",
      "-append", "console=ttyS0 panic=-1",
    ]))

    machine = create_machine({"startCommand": flags})

    machine.start()
    machine.wait_for_console_text("roothash invalid or missing")
  '';
})) (_: {})
