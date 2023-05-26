# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../lib/eval-config.nix ({ config, ... }:

let
  rootfs = import ../../host/rootfs { inherit config; };
  initramfs = import ../../host/initramfs { inherit config rootfs; };
in

config.pkgs.nixosTest ({ stdenv, ... }: {
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
}))
