# SPDX-License-Identifier: EUPL-1.2+
# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

project('surface-notify', 'c', default_options : [ 'warning_level=2' ])

libweston = dependency('libweston-13')
wayland_server = dependency('wayland-server')

shared_library('surface-notify', 'module.c',
  name_prefix : '',
  dependencies : [ libweston, wayland_server ],
  install : true,
  install_dir : get_option('libdir') / 'weston')
