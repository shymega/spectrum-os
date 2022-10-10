// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

use std::fs::{create_dir, create_dir_all, File};
use std::os::unix::fs::symlink;

use start_vm::vm_command;
use test_helper::TempDir;

fn contains_seq<H: PartialEq<N>, N>(haystack: &[H], needle: &[N]) -> bool {
    let start_indexes = 0..=(haystack.len() - needle.len());
    let mut candidates = start_indexes.map(|i| &haystack[i..][..needle.len()]);
    candidates.any(|c| c == needle)
}

fn main() -> std::io::Result<()> {
    let tmp_dir = TempDir::new()?;

    let service_dir = tmp_dir.path().join("testvm");
    let vm_config = tmp_dir.path().join("svc/data/testvm");

    create_dir(&service_dir)?;
    create_dir_all(&vm_config)?;
    File::create(vm_config.join("vmlinux"))?;
    create_dir(vm_config.join("blk"))?;
    symlink("/dev/null", vm_config.join("blk/root.img"))?;

    create_dir(vm_config.join("shared-dirs"))?;
    create_dir(vm_config.join("shared-dirs/root"))?;
    symlink("/", vm_config.join("shared-dirs/root/dir"))?;

    let expected_args = [
        "--fs",
        "tag=root,socket=../testvm-fs-root/env/virtiofsd.sock",
    ];

    let command = vm_command(service_dir, &tmp_dir.path().join("svc/data")).unwrap();
    let args: Box<[_]> = command.get_args().collect();
    assert!(contains_seq(&args, &expected_args));
    Ok(())
}
