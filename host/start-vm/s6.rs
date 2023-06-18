// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

use std::fs::File;
use std::io::Write;
use std::os::unix::prelude::*;

/// # Safety
///
/// Can only be called once per process, because afterwards the descriptor will be
/// closed.
pub unsafe fn notify_readiness() -> Result<(), String> {
    let mut supervisor = File::from_raw_fd(3);
    writeln!(supervisor).map_err(|e| format!("notifying readiness: {e}"))
}
