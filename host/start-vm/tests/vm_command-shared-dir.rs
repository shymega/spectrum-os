// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>

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
    symlink("/dev/null", vm_config.join("blk/root.img"))?;

    create_dir(vm_config.join("shared-dirs"))?;

    create_dir(vm_config.join("shared-dirs/dir1"))?;
    symlink("/", vm_config.join("shared-dirs/dir1/dir"))?;

    create_dir(vm_config.join("shared-dirs/dir2"))?;
    symlink("/", vm_config.join("shared-dirs/dir2/dir"))?;

    let command = vm_command(service_dir, -1).unwrap();
    let args: Box<[_]> = command.get_args().collect();

    for i in 1..=2 {
        let expected_fs_arg = format!("tag=dir{i},socket=../testvm-fs-dir{i}/env/virtiofsd.sock");
        assert!(contains_seq(&args, &["--fs", &expected_fs_arg]));
    }

    Ok(())
}
