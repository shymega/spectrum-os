// SPDX-License-Identifier: EUPL-1.2
// SPDX-FileCopyrightText: 2022 Alyssa Ross <hi@alyssa.is>

int if_up(const char *name);

int bridge_add(const char *name);
int bridge_add_if(const char *brname, const char *ifname);
int bridge_delete(const char *name);

int tap_open(const char *name, int flags);
int tap_delete(const char *name);
