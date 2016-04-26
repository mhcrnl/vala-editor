ACLOCAL_AMFLAGS = -I m4
    SUBDIRS = src
    EXTRA_DIST = autogen.sh

DISTCLEANFILES = aclocal.m4 ar-lib compile configure config.* \
	depcomp install-sh libtool ltmain.sh missing Makefile.in vala-editor.edi

distclean-local:
	rm -rf autom4te.cache
	rm -rf m4
