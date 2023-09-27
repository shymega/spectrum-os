# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

import ../../../lib/eval-config.nix ({ config, ... }:

let
  inherit (import ../../../host/rootfs { inherit config; }) appvm;
  run = import ../../../vm/app/foot.nix { inherit config; };
  surface-notify = import ./surface-notify { inherit config; };
in

config.pkgs.nixosTest ({ lib, pkgs, ... }: {
  name = "spectrum-wayland";

  nodes.machine = { ... }: {
    hardware.opengl.enable = true;

    systemd.services.cloud-hypervisor = {
      after = [ "crosvm-gpu.service" "weston.service" ];
      requires = [ "crosvm-gpu.service" "weston.service" ];
      serviceConfig.ExecStart = "${lib.getExe pkgs.cloud-hypervisor} --memory shared=on --disk path=${appvm}/img/appvm/blk/root.img,readonly=on --disk path=${run}/blk/run.img,readonly=on --cmdline \"console=ttyS0 root=PARTLABEL=root\" --gpu socket=/run/crosvm-gpu.sock --serial tty --console null --kernel ${appvm}/img/appvm/vmlinux";
    };

    systemd.services.crosvm = {
      after = [ "crosvm-gpu.service" "weston.service" ];
      requires = [ "crosvm-gpu.service" "weston.service" ];
      serviceConfig.ExecStart = "${lib.getExe pkgs.crosvm} run -s /run/crosvm --disk ${appvm}/img/appvm/blk/root.img --disk ${run}/blk/run.img -p \"console=ttyS0 root=PARTLABEL=root\" --vhost-user-gpu /run/crosvm-gpu.sock --serial type=stdout,hardware=virtio-console,stdin=true ${appvm}/img/appvm/vmlinux";
      serviceConfig.ExecStop = "${lib.getExe pkgs.crosvm} stop /run/crosvm";
    };

    systemd.services.crosvm-gpu = {
      requires = [ "weston.service" ];
      script = ''
        rm -f /run/crosvm-gpu.sock
        (
            while ! [ -S /run/crosvm-gpu.sock ]; do
                sleep .1
            done
            systemd-notify --ready --no-block
        ) &
        exec ${lib.getExe pkgs.crosvm} device gpu \
            --socket /run/crosvm-gpu.sock \
            --wayland-sock /run/wayland-1 \
            --params '{"context-types":"cross-domain"}'
      '';
      serviceConfig.NotifyAccess = "all";
      serviceConfig.Type = "notify";
    };

    systemd.services.surface-notify-socket = {
      serviceConfig.ExecStart = "${pkgs.coreutils}/bin/mkfifo /run/surface-notify";
      serviceConfig.RemainAfterExit = true;
      serviceConfig.Type = "oneshot";
    };

    systemd.services.weston = {
      after = [ "surface-notify-socket.service" ];
      requires = [ "surface-notify-socket.service" ];
      environment.XDG_RUNTIME_DIR = "/run";
      environment.WAYLAND_DEBUG = "server";
      serviceConfig.ExecStart = "${lib.getExe pkgs.westonLite} --modules ${surface-notify}/lib/weston/surface-notify.so,systemd-notify.so";
      serviceConfig.TTYPath = "/dev/tty7";
      serviceConfig.Type = "notify";
    };
  };

  testScript = { ... }: ''
    machine.wait_for_unit('multi-user.target')

    machine.start_job('crosvm.service')
    machine.wait_for_unit('surface-notify-socket.service');
    machine.succeed('test "$(wc -c /run/surface-notify)" = "1 /run/surface-notify"', timeout=180)
    machine.screenshot('crosvm')
    machine.stop_job('crosvm-gpu.service')
    machine.stop_job('crosvm.service')

    machine.start_job('cloud-hypervisor.service')
    machine.succeed('test "$(wc -c /run/surface-notify)" = "1 /run/surface-notify"', timeout=180)
    machine.screenshot('cloud-hypervisor')
  '';
}))
