# SPDX-License-Identifier: EUPL-1.2+
# SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

project('start-vm', 'rust', 'c',
  default_options : ['c_std=c2x', 'rust_std=2018', 'warning_level=3'])

add_project_arguments('-D_GNU_SOURCE', '-Wno-error=attributes', language : 'c')
add_project_arguments('-C', 'panic=abort', language : 'rust')

c_lib = static_library('start-vm', 'net.c', 'net-util.c', 'unix.c')
rust_lib = static_library('start_vm', 'lib.rs', link_with : c_lib)

executable('start-vm', 'start-vm.rs', link_with : rust_lib, install : true)

test_exe = executable('start-vm-test', 'lib.rs',
  rust_args : ['--test', '-C', 'panic=unwind'],
  link_with : c_lib)
test('Rust unit tests', test_exe, protocol : 'rust')

subdir('tests')
