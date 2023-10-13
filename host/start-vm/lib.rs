// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>
// SPDX-FileCopyrightText: 2022 Unikie

mod ch;
mod net;
mod s6;
mod unix;

use std::borrow::Cow;
use std::env::args_os;
use std::ffi::{CString, OsStr, OsString};
use std::fs::remove_file;
use std::io::{self, ErrorKind};
use std::os::unix::net::UnixListener;
use std::os::unix::prelude::*;
use std::path::{Path, PathBuf};
use std::process::Command;

use net::{format_mac, net_setup, NetConfig};
use unix::clear_cloexec;

pub use s6::notify_readiness;

pub fn prog_name() -> String {
    args_os()
        .next()
        .as_ref()
        .map(Path::new)
        .and_then(Path::file_name)
        .map(OsStr::to_string_lossy)
        .unwrap_or(Cow::Borrowed("start-vm"))
        .into_owned()
}

pub fn create_api_socket() -> Result<UnixListener, String> {
    let _ = remove_file("env/cloud-hypervisor.sock");
    let api_socket = UnixListener::bind("env/cloud-hypervisor.sock")
        .map_err(|e| format!("creating API socket: {e}"))?;

    // Safe because we own api_socket.
    if unsafe { clear_cloexec(api_socket.as_fd()) } == -1 {
        let errno = io::Error::last_os_error();
        return Err(format!("clearing CLOEXEC on API socket fd: {}", errno));
    }

    Ok(api_socket)
}

pub fn vm_command(dir: PathBuf, api_socket_fd: RawFd) -> Result<Command, String> {
    let vm_name = dir
        .file_name()
        .ok_or_else(|| "directory has no name".to_string())?;

    if vm_name.as_bytes().contains(&b',') {
        return Err(format!("VM name may not contain a comma: {:?}", vm_name));
    }

    let config_dir = dir.join("data/config");

    let mut command = Command::new("cloud-hypervisor");
    command.args(["--api-socket", &format!("fd={api_socket_fd}")]);
    command.args(["--cmdline", "console=ttyS0 root=PARTLABEL=root"]);
    command.args(["--memory", "size=128M,shared=on"]);
    command.args(["--console", "pty"]);
    command.arg("--kernel");
    command.arg(config_dir.join("vmlinux"));

    let net_providers_dir = config_dir.join("providers/net");
    match net_providers_dir.read_dir() {
        Ok(entries) => {
            // TODO: to support multiple net providers, we'll need
            // a better naming scheme for tap and bridge devices.
            #[allow(clippy::never_loop)]
            for r in entries {
                let entry = r
                    .map_err(|e| format!("examining directory entry: {}", e))?
                    .file_name();

                // Safe because provider_name is the name of a directory entry, so
                // can't contain a null byte.
                let provider_name = unsafe { CString::from_vec_unchecked(entry.into_vec()) };

                // Safe because we pass a valid pointer and check the result.
                let NetConfig { fd, mac } = unsafe { net_setup(provider_name.as_ptr()) };
                if fd == -1 {
                    let e = io::Error::last_os_error();
                    return Err(format!("setting up networking failed: {}", e));
                }

                command
                    .arg("--net")
                    .arg(format!("fd={},mac={}", fd, format_mac(&mac)));

                break;
            }
        }
        Err(e) if e.kind() == ErrorKind::NotFound => {}
        Err(e) => return Err(format!("reading directory {:?}: {}", net_providers_dir, e)),
    }

    let blk_dir = config_dir.join("blk");
    match blk_dir.read_dir() {
        Ok(entries) => {
            for result in entries {
                let entry = result
                    .map_err(|e| format!("examining directory entry: {}", e))?
                    .path();

                if entry.extension() != Some(OsStr::new("img")) {
                    continue;
                }

                if entry.as_os_str().as_bytes().contains(&b',') {
                    return Err(format!("illegal ',' character in path {:?}", entry));
                }

                let mut arg = OsString::from("path=");
                arg.push(entry);
                arg.push(",readonly=on");
                command.arg("--disk").arg(arg);
            }
        }
        Err(e) => return Err(format!("reading directory {:?}: {}", blk_dir, e)),
    }

    if config_dir.join("wayland").exists() {
        command.arg("--gpu").arg({
            let mut gpu = OsString::from("socket=../");
            gpu.push(vm_name);
            gpu.push("-gpu/env/crosvm.sock");
            gpu
        });
    }

    let shared_dirs_dir = config_dir.join("shared-dirs");
    match shared_dirs_dir.read_dir() {
        Ok(entries) => {
            for result in entries {
                let entry = result
                    .map_err(|e| format!("examining directory entry: {}", e))?
                    .file_name();

                let mut arg = OsString::from("tag=");
                arg.push(&entry);
                arg.push(",socket=../");
                arg.push(vm_name);
                arg.push("-fs-");
                arg.push(&entry);
                arg.push("/env/virtiofsd.sock");
                command.arg("--fs").arg(arg);
            }
        }
        Err(e) if e.kind() == ErrorKind::NotFound => {}
        Err(e) => return Err(format!("reading directory {:?}: {}", shared_dirs_dir, e)),
    }

    command.arg("--serial").arg({
        let mut serial = OsString::from("file=/run/");
        serial.push(vm_name);
        serial.push(".log");
        serial
    });

    Ok(command)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_vm_name_comma() {
        assert!(vm_command("/v,m".into(), -1).unwrap_err().contains("comma"));
    }
}
