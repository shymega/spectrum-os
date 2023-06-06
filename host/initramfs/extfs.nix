# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ config, runCommand, e2fsprogs }:

let
  netvm = import ../../vm/sys/net {
    inherit config;
    # inherit (foot) terminfo;
  };

  appvm-catgirl = import ../../vm/app/catgirl.nix { inherit config; };
  appvm-foot = import ../../vm/app/foot.nix { inherit config; };
  appvm-hello-wayland = import ../../vm/app/hello-wayland.nix { inherit config; };
  appvm-lynx = import ../../vm/app/lynx.nix { inherit config; };
  appvm-mg = import ../../vm/app/mg.nix { inherit config; };
in

runCommand "ext.ext4" {
  nativeBuildInputs = [ e2fsprogs ];
} ''
  mkdir -p root/svc/data/appvm-{catgirl,foot,hello-wayland,lynx,mg}
  cd root

  tar -C ${netvm} -c data | tar -C svc -x
  chmod +w svc/data

  tar -C ${appvm-catgirl} -c . | tar -C svc/data/appvm-catgirl -x
  tar -C ${appvm-foot} -c . | tar -C svc/data/appvm-foot -x
  tar -C ${appvm-hello-wayland} -c . | tar -C svc/data/appvm-hello-wayland -x
  tar -C ${appvm-lynx} -c . | tar -C svc/data/appvm-lynx -x
  tar -C ${appvm-mg} -c . | tar -C svc/data/appvm-mg -x

  mkfs.ext4 -d . $out 16T
  resize2fs -M $out

  # The generated image will have all files owned by the uid and gid
  # mkfs.ext4 was run as, so we need to normalize ownership to root.
  find -exec echo $'set_inode_field {} uid 0\nset_inode_field {} gid 0' ';' |
      debugfs -wf - $out
''
