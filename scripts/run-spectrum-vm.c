// SPDX-License-Identifier: EUPL-1.2+
// SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>

#include <assert.h>
#include <err.h>
#include <errno.h>
#include <sched.h>
#include <signal.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>
#include <unistd.h>

#include <sys/mount.h>
#include <sys/poll.h>
#include <sys/prctl.h>
#include <sys/stat.h>

#include <linux/prctl.h>

static const char *tmpdir(void)
{
	static char *d;
	if (!d)
		d = getenv("TMPDIR");
	if (!d)
		d = "/tmp";
	return d;
}

static noreturn void exit_listener_main(int fd, const char *dir_path)
{
	struct pollfd pollfd = { .fd = fd, .events = 0, .revents = 0 };

	if (signal(SIGINT, SIG_IGN) == SIG_ERR)
		warn("ignoring SIGINT");
	if (signal(SIGTERM, SIG_IGN) == SIG_ERR)
		warn("ignoring SIGTERM");

	// Wait for the other end of the pipe to be closed.
	while (poll(&pollfd, 1, -1) == -1) {
		if (errno == EINTR || errno == EWOULDBLOCK)
			continue;

		err(EXIT_FAILURE, "poll");
	}
	assert(pollfd.revents == POLLERR);

	execlp("rm", "rm", "-rf", "--", dir_path, NULL);
	err(EXIT_FAILURE, "exec rm");
}

static void exit_listener_setup(const char *dir_path)
{
	int fd[2];

	if (pipe(fd) == -1)
		err(EXIT_FAILURE, "pipe");

	switch (fork()) {
	case -1:
		close(fd[0]);
		close(fd[1]);
		err(EXIT_FAILURE, "fork");
	case 0:
		close(fd[0]);
		exit_listener_main(fd[1], dir_path);
	default:
		close(fd[1]);
	}
}

static char *const virtiofsd_argv[] = {
	"virtiofsd",
	"--socket-path", "../vm-fs-virtiofs0/env/virtiofsd.sock",
	"--sandbox", "none",
	"--shared-dir", "/",
	NULL
};

static void spawn_virtiofsd(void)
{
	sigset_t sigset;
	pid_t ppid = getpid();

	switch (fork()) {
	case -1:
		err(EXIT_FAILURE, "fork");
	case 0:
		if (prctl(PR_SET_PDEATHSIG, SIGTERM) == -1)
			err(EXIT_FAILURE, "prctl PR_SET_DEATHSIG");
		if (getppid() != ppid)
			exit(EXIT_SUCCESS);
		if (sigemptyset(&sigset) == -1)
			err(EXIT_FAILURE, "sigemptyset");
		if (sigaddset(&sigset, SIGINT) == -1)
			err(EXIT_FAILURE, "sigaddset");
		if (sigprocmask(SIG_BLOCK, &sigset, NULL) == -1)
			err(EXIT_FAILURE, "sigprocmask");
		execv(VIRTIOFSD_PATH, virtiofsd_argv);
		err(EXIT_FAILURE, "exec " VIRTIOFSD_PATH);
	}
}

int main(void)
{
	int fd;
	char *dir_path;

	if (asprintf(&dir_path, "%s/run-spectrum-vm.XXXXXX", tmpdir()) == -1)
		err(EXIT_FAILURE, NULL);

	if (!mkdtemp(dir_path))
		err(EXIT_FAILURE, "mkdtemp");

	exit_listener_setup(dir_path);

	if (chdir(dir_path) == -1)
		err(EXIT_FAILURE, "chdir %s", dir_path);

	if (mkdir("bin", 0777) == -1)
		err(EXIT_FAILURE, "mkdir bin");
	if (mkdir("dev", 0777) == -1)
		err(EXIT_FAILURE, "mkdir dev");
	if (mkdir("nix", 0777) == -1)
		err(EXIT_FAILURE, "mkdir nix");
	if (mkdir("proc", 0777) == -1)
		err(EXIT_FAILURE, "mkdir proc");
	if (mkdir("run", 0777) == -1)
		err(EXIT_FAILURE, "mkdir run");
	if (mkdir("vm-fs-virtiofs0", 0777) == -1)
		err(EXIT_FAILURE, "mkdir vm-fs-virtiofs0");
	if (mkdir("vm-fs-virtiofs0/env", 0777) == -1)
		err(EXIT_FAILURE, "mkdir vm-fs-virtiofs0/env");
	if (mkdir("vm", 0777) == -1)
		err(EXIT_FAILURE, "mkdir vm");

	if (open("bin/cloud-hypervisor", O_CLOEXEC|O_CREAT|O_EXCL, 0) == -1)
		err(EXIT_FAILURE, "create bin/cloud-hypervisor");

	if (chdir("vm") == -1)
		err(EXIT_FAILURE, "chdir vm");
	if (mkdir("env", 0777) == -1)
		err(EXIT_FAILURE, "mkdir env");
	if (mkdir("data", 0777) == -1)
		err(EXIT_FAILURE, "mkdir data");

	if (symlink(CONFIG_PATH, "data/config") == -1)
		err(EXIT_FAILURE, "symlink data/config -> " CONFIG_PATH);
	if (symlink(APPVM_PATH, "../usr") == -1)
		err(EXIT_FAILURE, "symlink ../usr -> " APPVM_PATH);

	spawn_virtiofsd();

	if ((fd = open("/dev/null", O_WRONLY)) == -1)
		err(EXIT_FAILURE, "open /dev/null");
	if (dup2(fd, 3) == -1)
		err(EXIT_FAILURE, "dup2 %d -> 3", fd);
	if (fd != 3)
		close(fd);

	if ((fd = open(START_VMM_PATH, O_PATH|O_CLOEXEC)) == -1)
		err(EXIT_FAILURE, "open " START_VMM_PATH);

	if (unshare(CLONE_NEWUSER|CLONE_NEWNS) == -1)
		err(EXIT_FAILURE, "unshare");
	if (mount(CLOUD_HYPERVISOR_PATH, "../bin/cloud-hypervisor", NULL, MS_BIND, NULL) == -1)
		err(EXIT_FAILURE, "bind mount " CLOUD_HYPERVISOR_PATH " -> ../bin/cloud-hypervisor");
	if (mount("/dev", "../dev", NULL, MS_BIND|MS_REC, NULL) == -1)
		err(EXIT_FAILURE, "bind mount /dev -> ../dev");
	if (mount("/nix", "../nix", NULL, MS_BIND|MS_REC, NULL) == -1)
		err(EXIT_FAILURE, "bind mount /nix -> ../nix");
	if (mount("/proc", "../proc", NULL, MS_BIND|MS_REC, NULL) == -1)
		err(EXIT_FAILURE, "bind mount /proc -> ../proc");
	if (chroot(dir_path) == -1)
		err(EXIT_FAILURE, "chroot");

	fexecve(fd, (char *const []){"start-vmm", NULL}, (char *const []){"PATH=/bin", NULL});
	err(EXIT_FAILURE, "exec " START_VMM_PATH);
}
