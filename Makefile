prefix := $(HOME)

bindir := $(prefix)/bin
mandir := $(prefix)/share/man/man1

all: doc

doc: doc/git-reintegrate.1

test:
	$(MAKE) -C test

doc/git-reintegrate.1: doc/git-reintegrate.txt
	asciidoctor -b manpage $<

clean:
	$(RM) doc/git-reintegrate.1

D = $(DESTDIR)

install:
	install -d -m 755 $(D)$(bindir)/
	install -m 755 git-reintegrate $(D)$(bindir)/git-reintegrate

install-doc: doc
	install -d -m 755 $(D)$(mandir)/
	install -m 644 doc/git-reintegrate.1 $(D)$(mandir)/git-reintegrate.1

.PHONY: all doc test install install-doc clean
