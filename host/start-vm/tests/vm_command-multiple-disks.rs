// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>

use std::ffi::{OsStr, OsString};
use std::fs::{create_dir, create_dir_all, File};
use std::os::unix::fs::symlink;

use start_vm::vm_command;
use test_helper::{contains_seq, TempDir};

fn main() -> std::io::Result<()> {
    let tmp_dir = TempDir::new()?;

    let service_dir = tmp_dir.path().join("testvm");
    let vm_config = service_dir.join("data/config");

    create_dir_all(&vm_config)?;
    File::create(vm_config.join("vmlinux"))?;
    create_dir(vm_config.join("blk"))?;

    let image_paths: Vec<_> = (1..=2)
        .map(|n| vm_config.join(format!("blk/disk{n}.img")))
        .collect();

    for image_path in &image_paths {
        symlink("/dev/null", image_path)?;
    }

    let command = vm_command(&service_dir, -1).unwrap();
    let args: Box<[_]> = command.get_args().collect();

    for image_path in &image_paths {
        let mut expected_disk_arg = OsString::from("path=");
        expected_disk_arg.push(image_path);
        expected_disk_arg.push(",readonly=on");

        let expected_args = [OsStr::new("--disk"), &expected_disk_arg];
        assert!(contains_seq(&args, &expected_args));
    }

    Ok(())
}
