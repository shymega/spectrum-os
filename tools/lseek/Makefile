# SPDX-FileCopyrightText: 2023 Alyssa Ross <hi@alyssa.is>
# SPDX-License-Identifier: EUPL-1.2+

.POSIX:

CFLAGS = -Wall -Wextra -Wpedantic -O -g
INSTALL = install
INSTALL_PROGRAM = $(INSTALL)

prefix = /usr/local
bindir = $(prefix)/bin

all: lseek
.PHONY: all

install: lseek
	mkdir -p $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) lseek $(DESTDIR)$(bindir)
.PHONY: install

clean:
	rm -f lseek *.o
.PHONY: clean
