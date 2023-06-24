# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

project('quote', 'rust', version : '1.0.35',
  default_options : ['build.rust_std=2018', 'rust_std=2018'])

proc_macro2_dep = dependency('proc-macro2', native : true)

quote = static_library('quote', 'src/lib.rs',
  dependencies : proc_macro2_dep,
  native : true,
  rust_args : ['-C', 'panic=unwind'],
  rust_crate_type : 'rlib')

quote_dep = declare_dependency(
  dependencies : proc_macro2_dep,
  link_with : quote)

meson.override_dependency('quote', quote_dep, native : true)
