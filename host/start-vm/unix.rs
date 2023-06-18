// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

use std::ffi::c_int;
use std::os::fd::BorrowedFd;

extern "C" {
    pub fn clear_cloexec(fd: BorrowedFd) -> c_int;
}
