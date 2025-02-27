# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: MIT

(final: super: {
  cloud-hypervisor = import ./cloud-hypervisor { inherit final super; };

  dbus = import ./dbus { inherit final super; };
})
