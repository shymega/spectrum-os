# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ config, runCommand, e2fsprogs, tar2ext4 }:

let
  netvm = import ../../vm/sys/net {
    inherit config;
    # inherit (foot) terminfo;
  };

  appvm-catgirl = import ../../vm/app/catgirl.nix { inherit config; };
  appvm-lynx = import ../../vm/app/lynx.nix { inherit config; };
in

runCommand "ext.ext4" {
  nativeBuildInputs = [ e2fsprogs ];
} ''
  mkdir -p root/svc/data/appvm-{catgirl,lynx}
  cd root

  tar -C ${netvm} -c data | tar -C svc -x
  chmod +w svc/data

  tar -C ${appvm-catgirl} -c . | tar -C svc/data/appvm-catgirl -x
  tar -C ${appvm-lynx} -c . | tar -C svc/data/appvm-lynx -x

  mkfs.ext4 -d . $out 16T
  resize2fs -M $out

  # The generated image will have all files owned by the uid and gid
  # mkfs.ext4 was run as, so we need to normalize ownership to root.
  find -exec echo $'set_inode_field {} uid 0\nset_inode_field {} gid 0' ';' |
      debugfs -wf - $out
''
