// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

// A Weston module that sends a notification into a fifo when a
// window with a specific app ID appears.

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#include <libweston/desktop.h>

static const char APP_ID[] = "foot";

static void on_commit(struct wl_listener *, struct weston_surface *surface)
{
	struct weston_desktop_surface *desktop_surface;
	int fd;

	if (!(desktop_surface = weston_surface_get_desktop_surface(surface)))
		return;
	if (strcmp(weston_desktop_surface_get_app_id(desktop_surface), APP_ID))
		return;

	if ((fd = open("/run/surface-notify", O_RDWR)) == -1) {
		weston_log("opening /run/surface-notify: %s\n", strerror(errno));
		return;
	}

	if (write(fd, "\n", 1) == -1)
		weston_log("writing to /run/surface-notify: %s\n", strerror(errno));

	close(fd);
}

static void on_destroy(struct wl_listener *listener,
		       struct weston_surface *surface)
{
	struct wl_listener *commit_listener = wl_signal_get(
		&surface->commit_signal, (wl_notify_func_t)on_commit);

	wl_list_remove(&commit_listener->link);
	free(commit_listener);

	wl_list_remove(&listener->link);
	free(listener);
}

static void add_listener(struct wl_signal *signal, wl_notify_func_t notify)
{
	struct wl_listener *listener = zalloc(sizeof *listener);
	if (!listener) {
		weston_log("failed to allocate listener\n");
		return;
	}

	listener->notify = notify;
	wl_signal_add(signal, listener);
}

static void on_create(struct wl_listener *, struct weston_surface *surface)
{
	add_listener(&surface->commit_signal, (wl_notify_func_t)on_commit);
	add_listener(&surface->destroy_signal, (wl_notify_func_t)on_destroy);
}

static struct wl_listener create_surface_listener = {
	.notify = (wl_notify_func_t)on_create,
};

int wet_module_init(struct weston_compositor *compositor, int *, char *[])
{
	wl_signal_add(&compositor->create_surface_signal,
		      &create_surface_listener);

	return 0;
}
