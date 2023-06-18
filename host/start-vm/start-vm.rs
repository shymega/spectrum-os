// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>

use std::env::current_dir;
use std::os::unix::prelude::*;
use std::path::Path;
use std::process::exit;

use start_vm::{create_api_socket, notify_readiness, prog_name, vm_command};

const CONFIG_ROOT: &str = "/ext/svc/data";

/// # Safety
///
/// Calls [`notify_readiness`], so can only be called once.
unsafe fn run() -> String {
    let dir = match current_dir().map_err(|e| format!("getting current directory: {}", e)) {
        Ok(dir) => dir,
        Err(e) => return e,
    };

    let api_socket = match create_api_socket() {
        Ok(api_socket) => api_socket,
        Err(e) => return e,
    };

    if let Err(e) = notify_readiness() {
        return e;
    }

    match vm_command(dir, Path::new(CONFIG_ROOT), api_socket.into_raw_fd()) {
        Ok(mut command) => format!("failed to exec: {}", command.exec()),
        Err(e) => e,
    }
}

fn main() {
    eprintln!("{}: {}", prog_name(), unsafe { run() });
    exit(1);
}
