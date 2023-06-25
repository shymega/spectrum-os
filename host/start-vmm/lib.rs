// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022-2023 Alyssa Ross <hi@alyssa.is>

mod ch;
mod fork;
mod net;
mod s6;
mod unix;

use std::borrow::Cow;
use std::env::args_os;
use std::ffi::{CString, OsStr};
use std::fs::remove_file;
use std::io::{self, ErrorKind};
use std::os::unix::net::UnixListener;
use std::os::unix::prelude::*;
use std::os::unix::process::parent_id;
use std::path::Path;
use std::process::{exit, Command};

use ch::{ConsoleConfig, DiskConfig, FsConfig, GpuConfig, MemoryConfig, PayloadConfig, VmConfig};
use fork::double_fork;
use net::net_setup;
use s6::notify_readiness;
use unix::clear_cloexec;

const SIGTERM: i32 = 15;

extern "C" {
    fn kill(pid: i32, sig: i32) -> i32;
}

pub fn prog_name() -> String {
    args_os()
        .next()
        .as_ref()
        .map(Path::new)
        .and_then(Path::file_name)
        .map(OsStr::to_string_lossy)
        .unwrap_or(Cow::Borrowed("start-vmm"))
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

pub fn vm_config(vm_name: &str, config_root: &Path) -> Result<VmConfig, String> {
    if config_root.to_str().is_none() {
        return Err(format!("config root {:?} is not valid UTF-8", config_root));
    }

    let config_dir = config_root.join(vm_name).join("config");

    let blk_dir = config_dir.join("blk");
    let kernel_path = config_dir.join("vmlinux");
    let net_providers_dir = config_dir.join("providers/net");
    let shared_dirs_dir = config_dir.join("shared-dirs");
    let wayland_path = config_dir.join("wayland");

    Ok(VmConfig {
        console: ConsoleConfig {
            mode: "Pty",
            file: None,
        },
        disks: match blk_dir.read_dir() {
            Ok(entries) => entries
                .into_iter()
                .map(|result| {
                    Ok(result
                        .map_err(|e| format!("examining directory entry: {e}"))?
                        .path())
                })
                .filter(|result| {
                    result
                        .as_ref()
                        .map(|entry| entry.extension() == Some(OsStr::new("img")))
                        .unwrap_or(true)
                })
                .map(|result: Result<_, String>| {
                    let entry = result?.to_str().unwrap().to_string();

                    if entry.contains(',') {
                        return Err(format!("illegal ',' character in path {:?}", entry));
                    }

                    Ok(DiskConfig {
                        path: entry,
                        readonly: true,
                    })
                })
                .collect::<Result<_, _>>()?,
            Err(e) => return Err(format!("reading directory {:?}: {}", blk_dir, e)),
        },
        fs: match shared_dirs_dir.read_dir() {
            Ok(entries) => entries
                .into_iter()
                .map(|result| {
                    let entry = result
                        .map_err(|e| format!("examining directory entry: {}", e))?
                        .file_name();

                    let entry = entry.to_str().ok_or_else(|| {
                        format!("shared directory name {:?} is not valid UTF-8", entry)
                    })?;

                    Ok(FsConfig {
                        tag: entry.to_string(),
                        socket: format!("/run/service/vhost-user-fs/instance/{vm_name}:{entry}/env/virtiofsd.sock"),
                    })
                })
                .collect::<Result<_, String>>()?,
            Err(e) if e.kind() == ErrorKind::NotFound => Default::default(),
            Err(e) => return Err(format!("reading directory {:?}: {e}", shared_dirs_dir)),
        },
        gpu: match wayland_path.try_exists() {
            Ok(true) => vec![GpuConfig {
                socket: format!("/run/service/vhost-user-gpu/instance/{vm_name}/env/crosvm.sock"),
            }],
            Ok(false) => vec![],
            Err(e) => return Err(format!("checking for existence of {:?}: {e}", wayland_path)),
        },
        memory: MemoryConfig {
            size: 256 << 20,
            shared: true,
        },
        net: match net_providers_dir.read_dir() {
            Ok(entries) => entries
                .into_iter()
                .map(|result| {
                    let entry = result
                        .map_err(|e| format!("examining directory entry: {}", e))?
                        .file_name();

                    // Safe because provider_name is the name of a directory entry, so
                    // can't contain a null byte.
                    let provider_name = unsafe { CString::from_vec_unchecked(entry.into_vec()) };

                    // Safe because we pass a valid pointer and check the result.
                    let net = unsafe { net_setup(provider_name.as_ptr()) };
                    if net.fd == -1 {
                        let e = io::Error::last_os_error();
                        return Err(format!("setting up networking failed: {e}"));
                    }

                    Ok(net)
                })
                // TODO: to support multiple net providers, we'll need
                // a better naming scheme for tap and bridge devices.
                .take(1)
                .collect::<Result<_, _>>()?,
            Err(e) if e.kind() == ErrorKind::NotFound => Default::default(),
            Err(e) => return Err(format!("reading directory {:?}: {e}", net_providers_dir)),
        },
        payload: PayloadConfig {
            kernel: kernel_path.to_str().unwrap().to_string(),
            cmdline: "console=ttyS0 root=PARTLABEL=root",
        },
        serial: ConsoleConfig {
            mode: "File",
            file: Some(format!("/run/{vm_name}.log")),
        },
    })
}

/// # Safety
///
/// Calls [notify_readiness], so can only be called once per process.
unsafe fn create_vm_child_main(vm_name: &str, config: VmConfig) -> ! {
    if let Err(e) = ch::create_vm(vm_name, config) {
        eprintln!("{}: creating VM: {e}", prog_name());
        if kill(parent_id() as _, SIGTERM) == -1 {
            let e = io::Error::last_os_error();
            eprintln!("{}: killing cloud-hypervisor: {e}", prog_name());
        };
        exit(1);
    }

    if let Err(e) = notify_readiness() {
        eprintln!("{}: failed to notify readiness: {e}", prog_name());
        exit(1);
    }

    exit(0)
}

pub fn create_vm(dir: &Path, config_root: &Path) -> Result<(), String> {
    let vm_name = dir
        .file_name()
        .ok_or_else(|| "directory has no name".to_string())?;

    let vm_name = &vm_name
        .to_str()
        .ok_or_else(|| format!("VM name {:?} is not valid UTF-8", vm_name))?;

    if vm_name.contains(':') {
        return Err(format!("VM name may not contain a colon: {:?}", vm_name));
    }

    let config = vm_config(vm_name, config_root)?;

    // SAFETY: safe because we ensure we don't violate any invariants
    // concerning OS resources shared between processes, by only
    // passing data structs to the child main function.
    match unsafe { double_fork() } {
        e if e < 0 => Err(format!("double fork: {}", io::Error::from_raw_os_error(-e))),
        // SAFETY: create_vm_child_main can only be called once per process,
        // but this is a new process, so we know it hasn't been called before.
        0 => unsafe { create_vm_child_main(vm_name, config) },
        _ => Ok(()),
    }
}

pub fn vm_command(api_socket_fd: RawFd) -> Result<Command, String> {
    let mut command = Command::new("cloud-hypervisor");
    command.args(["--api-socket", &format!("fd={api_socket_fd}")]);

    Ok(command)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_vm_name_colon() {
        let e = create_vm(Path::new("/:vm"), Path::new("/")).unwrap_err();
        assert!(e.contains("colon"), "unexpected error: {:?}", e);
    }
}
