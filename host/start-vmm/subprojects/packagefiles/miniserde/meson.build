# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

project('miniserde', 'rust', version : '0.1.37',
  default_options : ['build.rust_std=2021', 'rust_std=2021'])

quote_dep = dependency('quote', native : true)
syn_dep = dependency('syn', native : true)

mini_internal = shared_library('mini_internal', 'derive/src/lib.rs',
  dependencies : [quote_dep, syn_dep],
  native : true,
  rust_args : ['-C', 'panic=unwind'],
  rust_crate_type : 'proc-macro')

itoa_dep = dependency('itoa')
ryu_dep = dependency('ryu')

miniserde = static_library('miniserde', 'src/lib.rs',
  dependencies : [itoa_dep, ryu_dep],
  link_with : mini_internal,
  rust_crate_type : 'rlib')

miniserde_dep = declare_dependency(
  dependencies : [itoa_dep, ryu_dep],
  link_with : miniserde)

meson.override_dependency('miniserde', miniserde_dep)
