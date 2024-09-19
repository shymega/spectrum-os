// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022-2024 Alyssa Ross <hi@alyssa.is>

use std::ffi::{CStr, OsStr, OsString};
use std::io::Write;
use std::mem::take;
use std::num::NonZeroI32;
use std::os::raw::{c_char, c_int};
use std::os::unix::prelude::*;
use std::path::PathBuf;
use std::process::{Command, Stdio};

use miniserde::{json, Serialize};

use crate::net::MacAddress;

// Trivially safe.
const EINVAL: NonZeroI32 = unsafe { NonZeroI32::new_unchecked(22) };
const EPERM: NonZeroI32 = unsafe { NonZeroI32::new_unchecked(1) };
const EPROTO: NonZeroI32 = unsafe { NonZeroI32::new_unchecked(71) };

#[derive(Serialize)]
pub struct ConsoleConfig {
    pub mode: &'static str,
    pub file: Option<String>,
}

#[derive(Serialize)]
pub struct DiskConfig {
    pub path: String,
    pub readonly: bool,
}

#[derive(Serialize)]
pub struct FsConfig {
    pub socket: String,
    pub tag: &'static str,
}

#[derive(Serialize)]
pub struct GpuConfig {
    pub socket: String,
}

#[derive(Serialize)]
#[repr(C)]
pub struct NetConfig {
    pub fd: RawFd,
    pub mac: MacAddress,
}

#[derive(Serialize)]
pub struct MemoryConfig {
    pub size: i64,
    pub shared: bool,
}

#[derive(Serialize)]
pub struct PayloadConfig {
    pub kernel: String,
    pub cmdline: &'static str,
}

#[derive(Serialize)]
pub struct VsockConfig {
    pub cid: u32,
    pub socket: &'static str,
}

#[derive(Serialize)]
pub struct VmConfig {
    pub console: ConsoleConfig,
    pub disks: Vec<DiskConfig>,
    pub fs: [FsConfig; 1],
    pub gpu: Vec<GpuConfig>,
    pub memory: MemoryConfig,
    pub net: Vec<NetConfig>,
    pub payload: PayloadConfig,
    pub serial: ConsoleConfig,
    pub vsock: VsockConfig,
}

fn command(vm_name: &str, s: impl AsRef<OsStr>) -> Command {
    let mut api_socket_path = PathBuf::from("/run/service/vmm/instance");
    api_socket_path.push(vm_name);
    api_socket_path.push("env/cloud-hypervisor.sock");

    let mut command = Command::new("ch-remote");
    command.stdin(Stdio::null());
    command.arg("--api-socket");
    command.arg(api_socket_path);
    command.arg(s);
    command
}

pub fn create_vm(vm_name: &str, mut config: VmConfig) -> Result<(), String> {
    // Net devices can't be created from file descriptors in vm.create.
    // https://github.com/cloud-hypervisor/cloud-hypervisor/issues/5523
    let nets = take(&mut config.net);

    let mut ch_remote = command(vm_name, "create")
        .args(["--", "-"])
        .stdin(Stdio::piped())
        .spawn()
        .map_err(|e| format!("failed to start ch-remote: {e}"))?;

    let json = json::to_string(&config);
    write!(ch_remote.stdin.as_ref().unwrap(), "{}", json)
        .map_err(|e| format!("writing to ch-remote's stdin: {e}"))?;

    let status = ch_remote
        .wait()
        .map_err(|e| format!("waiting for ch-remote: {e}"))?;
    if status.success() {
    } else if let Some(code) = status.code() {
        return Err(format!("ch-remote exited {code}"));
    } else {
        let signal = status.signal().unwrap();
        return Err(format!("ch-remote killed by signal {signal}"));
    }

    for net in nets {
        add_net(vm_name, &net).map_err(|e| format!("failed to add net: {e}"))?;
    }

    Ok(())
}

pub fn add_net(vm_name: &str, net: &NetConfig) -> Result<OsString, NonZeroI32> {
    let mut ch_remote = command(vm_name, "add-net")
        .arg(format!("fd={},mac={}", net.fd, net.mac))
        .stdout(Stdio::piped())
        .spawn()
        .or(Err(EPERM))?;

    let jq_out = match Command::new("jq")
        .args(["-j", ".id"])
        .stdin(ch_remote.stdout.take().unwrap())
        .stderr(Stdio::inherit())
        .output()
    {
        Ok(o) => o,
        Err(_) => {
            // Try not to leave a zombie.
            let _ = ch_remote.kill();
            let _ = ch_remote.wait();
            return Err(EPERM);
        }
    };

    if let Ok(ch_remote_status) = ch_remote.wait() {
        if ch_remote_status.success() && jq_out.status.success() {
            return Ok(OsString::from_vec(jq_out.stdout));
        }
    }

    Err(EPROTO)
}

pub fn remove_device(vm_name: &str, device_id: &OsStr) -> Result<(), NonZeroI32> {
    let ch_remote = command(vm_name, "remove-device")
        .arg(device_id)
        .status()
        .or(Err(EPERM))?;

    if ch_remote.success() {
        Ok(())
    } else {
        Err(EPROTO)
    }
}

/// # Safety
///
/// - `vm_name` must point to a valid C string.
#[export_name = "ch_add_net"]
unsafe extern "C" fn add_net_c(
    vm_name: *const c_char,
    net: &NetConfig,
    id: Option<&mut *mut OsString>,
) -> c_int {
    let Ok(vm_name) = CStr::from_ptr(vm_name).to_str() else {
        return EINVAL.into();
    };

    match add_net(vm_name, net) {
        Err(e) => e.get(),
        Ok(id_str) => {
            if let Some(id) = id {
                let token = Box::into_raw(Box::new(id_str));
                *id = token;
            }
            0
        }
    }
}

/// # Safety
///
/// - `vm_name` must point to a valid C string.
/// - `device_id` must be a device ID obtained by calling `add_net_c`.  After
///   calling `remove_device_c`, the pointer is no longer valid.
#[export_name = "ch_remove_device"]
unsafe extern "C" fn remove_device_c(vm_name: *const c_char, device_id: &mut OsString) -> c_int {
    let Ok(vm_name) = CStr::from_ptr(vm_name).to_str() else {
        return EINVAL.into();
    };
    let device_id = Box::from_raw(device_id);

    if let Err(e) = remove_device(vm_name, device_id.as_ref()) {
        e.get()
    } else {
        0
    }
}

/// # Safety
///
/// `id` must be a device ID obtained by calling `add_net_c`.  After
/// calling `device_free`, the pointer is no longer valid.
#[export_name = "ch_device_free"]
unsafe extern "C" fn device_free(id: Option<&mut OsString>) {
    if let Some(id) = id {
        drop(Box::from_raw(id))
    }
}
