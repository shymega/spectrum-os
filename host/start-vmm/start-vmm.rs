// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022-2024 Alyssa Ross <hi@alyssa.is>

use std::env::current_dir;
use std::os::unix::prelude::*;
use std::path::Path;
use std::process::exit;

use start_vmm::{create_api_socket, create_vm, prog_name, vm_command};

/// # Safety
///
/// Calls [`notify_readiness`], so can only be called once.
unsafe fn run() -> String {
    let dir = match current_dir().map_err(|e| format!("getting current directory: {}", e)) {
        Ok(dir) => dir,
        Err(e) => return e,
    };

    let Some(vm_name) = dir.file_name() else {
        return "directory has no name".to_string();
    };

    let vm_dir = Path::new("/run/vm").join(vm_name);

    let api_socket = match create_api_socket(&vm_dir) {
        Ok(api_socket) => api_socket,
        Err(e) => return e,
    };

    if let Err(e) = create_vm(&vm_dir) {
        return e;
    }

    match vm_command(api_socket.into_raw_fd()) {
        Ok(mut command) => format!("failed to exec: {}", command.exec()),
        Err(e) => e,
    }
}

fn main() {
    eprintln!("{}: {}", prog_name(), unsafe { run() });
    exit(1);
}
