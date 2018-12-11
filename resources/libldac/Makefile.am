include_HEADERS = \
	inc/ldacBT.h \
	abr/inc/ldacBT_abr.h

lib_LTLIBRARIES = \
	libldacBT.la \
	libldacBT_abr.la

libldacBT_la_CFLAGS = \
	-I$(top_srcdir)/inc
libldacBT_la_LDFLAGS = \
	-version-info 2:0:0
libldacBT_la_SOURCES = \
	src/ldaclib.c \
	src/ldacBT.c

libldacBT_abr_la_CFLAGS = \
	-I$(top_srcdir)/abr/inc \
	-I$(top_srcdir)/inc
libldacBT_abr_la_LDFLAGS = \
	-version-info 2:0:0
libldacBT_abr_la_SOURCES = \
	abr/src/ldacBT_abr.c

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = \
	libldacBT.pc \
	libldacBT_abr.pc
