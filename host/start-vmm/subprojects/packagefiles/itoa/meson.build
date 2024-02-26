# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

project('itoa', 'rust', version : '1.0.10', default_options : ['rust_std=2018'])

itoa = static_library('itoa', 'src/lib.rs', rust_crate_type : 'rlib')

itoa_dep = declare_dependency(link_with : itoa)

meson.override_dependency('itoa-rs', itoa_dep)
