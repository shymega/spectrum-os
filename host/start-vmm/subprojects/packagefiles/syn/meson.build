# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

project('syn', 'rust', version : '2.0.41',
  default_options : ['build.rust_std=2021', 'rust_std=2021'])

proc_macro2_dep = dependency('proc-macro2', native : true)
quote_dep = dependency('quote', native : true)

syn = static_library('syn', 'src/lib.rs',
  dependencies : [proc_macro2_dep, quote_dep],
  native : true,
  rust_args : [
    '-C', 'panic=unwind',
    '--cfg', 'feature="clone-impls"',
    '--cfg', 'feature="derive"',
    '--cfg', 'feature="parsing"',
    '--cfg', 'feature="printing"',
    '--cfg', 'feature="proc-macro"',
  ],
  rust_crate_type : 'rlib')

syn_dep = declare_dependency(
  dependencies : [proc_macro2_dep, quote_dep],
  link_with : syn)

meson.override_dependency('syn', syn_dep, native : true)
