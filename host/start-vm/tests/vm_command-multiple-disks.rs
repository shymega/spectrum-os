// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>

use std::collections::BTreeSet;
use std::ffi::{OsStr, OsString};
use std::fs::{create_dir, create_dir_all, File};
use std::os::unix::fs::symlink;

use start_vm::vm_command;
use test_helper::TempDir;

fn main() -> std::io::Result<()> {
    let service_dir_parent = TempDir::new()?;
    let service_dir = service_dir_parent.path().join("vm-testvm");

    let vm_dir = TempDir::new()?;
    let vm_config = vm_dir.path().join("testvm/config");

    create_dir_all(&vm_config)?;
    File::create(vm_config.join("vmlinux"))?;
    create_dir(vm_config.join("blk"))?;

    let image_paths: Vec<_> = (1..=2)
        .map(|n| vm_config.join(format!("blk/disk{n}.img")))
        .collect();

    for image_path in &image_paths {
        symlink("/dev/null", image_path)?;
    }

    let command = vm_command(&service_dir, vm_dir.path(), -1).unwrap();
    let mut args = command.get_args();

    assert!(args.any(|arg| arg == "--disk"));

    let expected_disk_args = image_paths
        .iter()
        .map(|image_path| {
            let mut expected_disk_arg = OsString::from("path=");
            expected_disk_arg.push(image_path);
            expected_disk_arg.push(",readonly=on");
            expected_disk_arg
        })
        .collect::<BTreeSet<_>>();

    let disk_args = args
        .map(OsStr::to_os_string)
        .take(expected_disk_args.len())
        .collect::<BTreeSet<_>>();

    assert_eq!(disk_args, expected_disk_args);

    Ok(())
}
