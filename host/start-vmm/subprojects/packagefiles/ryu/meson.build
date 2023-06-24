# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

project('ryu', 'rust', version : '1.0.17', default_options : ['rust_std=2018'])

ryu = static_library('ryu', 'src/lib.rs', rust_crate_type : 'rlib')

ryu_dep = declare_dependency(link_with : ryu)

meson.override_dependency('ryu', ryu_dep)
