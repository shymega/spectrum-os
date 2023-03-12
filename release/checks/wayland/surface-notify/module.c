// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

// A Weston module that sends a notification into a fifo when a
// hello-wayland window appears.

#include <fcntl.h>
#include <unistd.h>

#include <libweston/libweston.h>
#include <libweston/zalloc.h>

static void on_commit(struct wl_listener *, struct weston_surface *surface)
{
	int fd;
	int32_t width, height;

	// Use the size of the surface as a heuristic for identifying
	// hello-wayland.  If we had security contexts[1], we could be
	// more precise about this.
	//
	// [1]: https://gitlab.freedesktop.org/wayland/wayland-protocols/-/merge_requests/68
	weston_surface_get_content_size(surface, &width, &height);
	if (!surface->output || width != 128 || height != 128)
		return;

	if ((fd = open("/run/surface-notify", O_WRONLY)) == -1) {
		weston_log("opening /run/surface-notify: %m\n");
		return;
	}

	if (write(fd, "\n", 1) == -1)
		weston_log("writing to /run/surface-notify: %m\n");

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
