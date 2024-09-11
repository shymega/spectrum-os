// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022-2024 Alyssa Ross <hi@alyssa.is>

#include <stdint.h>

struct ch_device;

struct net_config {
	int fd;
	uint8_t mac[6];
};

int ch_add_net(const char vm_name[static 1], const struct net_config[static 1],
               struct ch_device **out);

[[gnu::nonnull]]
int ch_remove_device(const char vm_name[static 1], struct ch_device *);

void ch_device_free(struct ch_device *);
