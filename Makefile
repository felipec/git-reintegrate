prefix := $(HOME)

all:

doc: doc/git-reintegrate.1

test:
	$(MAKE) -C test

doc/git-reintegrate.1: doc/git-reintegrate.txt
	a2x -d manpage -f manpage $<

D = $(DESTDIR)

install:
	install -D -m 755 git-reintegrate \
		$(D)$(prefix)/bin/git-reintegrate

install-doc: doc
	install -D -m 644 doc/git-reintegrate.1 \
		$(D)$(prefix)/share/man/man1/git-reintegrate.1

.PHONY: all test
