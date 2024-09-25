// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2022-2024 Alyssa Ross <hi@alyssa.is>

#include <stdint.h>

#include <net/if.h>

struct ch_device;

struct net_config {
	int fd;
	char id[IFNAMSIZ];
	uint8_t mac[6];
};

int ch_add_net(const char vm_name[static 1], const struct net_config[static 1]);

int ch_remove_device(const char vm_name[static 1],
		     const char device_id[static 1]);
