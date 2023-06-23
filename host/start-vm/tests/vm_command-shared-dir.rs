// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>

use std::collections::BTreeSet;
use std::ffi::{OsStr, OsString};
use std::fs::{create_dir, create_dir_all, File};
use std::os::unix::fs::symlink;

use start_vm::vm_command;
use test_helper::TempDir;

fn main() -> std::io::Result<()> {
    let tmp_dir = TempDir::new()?;

    let service_dir = tmp_dir.path().join("vm-testvm");
    let vm_config = service_dir.join("data/config");

    create_dir_all(&vm_config)?;
    File::create(vm_config.join("vmlinux"))?;
    create_dir(vm_config.join("blk"))?;
    symlink("/dev/null", vm_config.join("blk/root.img"))?;

    create_dir(vm_config.join("shared-dirs"))?;

    create_dir(vm_config.join("shared-dirs/dir1"))?;
    symlink("/", vm_config.join("shared-dirs/dir1/dir"))?;

    create_dir(vm_config.join("shared-dirs/dir2"))?;
    symlink("/", vm_config.join("shared-dirs/dir2/dir"))?;

    let command = vm_command(&service_dir, -1).unwrap();
    let mut args = command.get_args();

    assert!(args.any(|arg| arg == "--fs"));

    let expected_fs_args = (1..=2)
        .map(|i| format!("tag=dir{i},socket=../fs-testvm-dir{i}/env/virtiofsd.sock"))
        .map(OsString::from)
        .collect::<BTreeSet<_>>();

    let fs_args = args
        .map(OsStr::to_os_string)
        .take(expected_fs_args.len())
        .collect::<BTreeSet<_>>();

    assert_eq!(fs_args, expected_fs_args);

    Ok(())
}
