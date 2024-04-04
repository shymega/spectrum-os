// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>

use std::fs::{create_dir_all, File};
use std::path::PathBuf;

use start_vmm::vm_config;
use test_helper::TempDir;

fn main() -> std::io::Result<()> {
    let tmp_dir = TempDir::new()?;

    let kernel_path = tmp_dir.path().join("testvm/config/vmlinux");
    let image_path = tmp_dir.path().join("testvm/config/blk/root.img");

    create_dir_all(kernel_path.parent().unwrap())?;
    create_dir_all(image_path.parent().unwrap())?;
    File::create(&kernel_path)?;
    File::create(&image_path)?;

    let mut config = vm_config("testvm", tmp_dir.path()).unwrap();

    assert_eq!(config.console.mode, "Pty");
    assert_eq!(config.disks.len(), 1);
    let disk1 = config.disks.pop().unwrap();
    assert_eq!(PathBuf::from(disk1.path), image_path);
    assert!(disk1.readonly);
    assert_eq!(PathBuf::from(config.payload.kernel), kernel_path);
    assert_eq!(config.payload.cmdline, "console=ttyS0 root=PARTLABEL=root");
    assert_eq!(config.memory.size, 0x10000000);
    assert!(config.memory.shared);
    assert_eq!(config.serial.mode, "File");
    assert_eq!(config.serial.file.unwrap(), "/run/testvm.log");

    Ok(())
}