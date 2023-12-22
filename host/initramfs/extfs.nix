# SPDX-FileCopyrightText: 2021-2022 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

{ callSpectrumPackage, runCommand, e2fsprogs }:

let
  netvm = callSpectrumPackage ../../vm/sys/net {
    # inherit (foot) terminfo;
  };

  appvm-catgirl = callSpectrumPackage ../../vm/app/catgirl.nix {};
  appvm-foot = callSpectrumPackage ../../vm/app/foot.nix {};
  appvm-gnome-text-editor = callSpectrumPackage ../../vm/app/gnome-text-editor.nix {};
  appvm-lynx = callSpectrumPackage ../../vm/app/lynx.nix {};
  appvm-mg = callSpectrumPackage ../../vm/app/mg.nix {};
in

runCommand "ext.ext4" {
  nativeBuildInputs = [ e2fsprogs ];
} ''
  mkdir -p root/svc/data/appvm-{catgirl,foot,gnome-text-editor,lynx,mg}
  cd root

  tar -C ${netvm} -c data | tar -C svc -x
  chmod +w svc/data

  tar -C ${appvm-catgirl} -c . | tar -C svc/data/appvm-catgirl -x
  tar -C ${appvm-foot} -c . | tar -C svc/data/appvm-foot -x
  tar -C ${appvm-gnome-text-editor} -c . | tar -C svc/data/appvm-gnome-text-editor -x
  tar -C ${appvm-lynx} -c . | tar -C svc/data/appvm-lynx -x
  tar -C ${appvm-mg} -c . | tar -C svc/data/appvm-mg -x

  mkfs.ext4 -d . $out 16T
  resize2fs -M $out

  # The generated image will have all files owned by the uid and gid
  # mkfs.ext4 was run as, so we need to normalize ownership to root.
  find -exec echo $'set_inode_field {} uid 0\nset_inode_field {} gid 0' ';' |
      debugfs -wf - $out
''
