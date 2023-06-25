// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>

use std::collections::BTreeSet;
use std::fs::{create_dir, create_dir_all, File};
use std::os::unix::fs::symlink;

use start_vmm::vm_config;
use test_helper::TempDir;

fn main() -> std::io::Result<()> {
    let tmp_dir = TempDir::new()?;

    let vm_config_dir = tmp_dir.path().join("testvm/config");

    create_dir_all(&vm_config_dir)?;
    File::create(vm_config_dir.join("vmlinux"))?;
    create_dir(vm_config_dir.join("blk"))?;
    symlink("/dev/null", vm_config_dir.join("blk/root.img"))?;

    create_dir(vm_config_dir.join("shared-dirs"))?;

    create_dir(vm_config_dir.join("shared-dirs/dir1"))?;
    symlink("/", vm_config_dir.join("shared-dirs/dir1/dir"))?;

    create_dir(vm_config_dir.join("shared-dirs/dir2"))?;
    symlink("/", vm_config_dir.join("shared-dirs/dir2/dir"))?;

    let config = vm_config("testvm", tmp_dir.path()).unwrap();
    assert_eq!(config.fs.len(), 2);

    let mut actual_tags = BTreeSet::new();
    let mut actual_sockets = BTreeSet::new();

    for fs in config.fs {
        actual_tags.insert(fs.tag);
        actual_sockets.insert(fs.socket);
    }

    let expected_tags = (1..=2).map(|i| format!("dir{i}")).collect();
    assert_eq!(actual_tags, expected_tags);

    let expected_sockets = (1..=2)
        .map(|i| format!("/run/service/vhost-user-fs/instance/testvm:dir{i}/env/virtiofsd.sock"))
        .collect();
    assert_eq!(actual_sockets, expected_sockets);

    Ok(())
}
