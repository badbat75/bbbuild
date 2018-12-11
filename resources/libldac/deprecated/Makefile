ifeq ($(PREFIX),)
    PREFIX := /usr/local
endif

ifeq ($(LIBDIR),)
    LIBDIR := /lib
endif

ifeq ($(INCLUDEDIR),)
    INCLUDEDIR := /include
endif

CC = gcc
AR = ar
CFLAGS += -Werror -Wall -Wextra -O3
INCLUDES += $(foreach h, $(INCLUDEFILES), -I$(h))
LIBS += -lm
LDFLAGS += 
LD_LIBRARY_PATH := 
RM = rm -f

INCLUDEFILES = abr/inc inc

SOURCES_ABR = abr/src/ldacBT_abr.c
STATIC_ABR = libldacBT_abr.a
LIB_ABR = libldacBT_abr.so
OBJS_ABR = $(SOURCES_ABR:.c=.o)

SOURCES_ENC = src/ldaclib.c src/ldacBT.c
STATIC_ENC = libldacBT_enc.a
LIB_ENC = libldacBT_enc.so
OBJS_ENC = $(SOURCES_ENC:.c=.o)

all: static libs

libs: $(LIB_ABR) $(LIB_ENC)

static: $(STATIC_ABR) $(STATIC_ENC)

$(STATIC_ABR): $(OBJS_ABR)
	${AR} rcs $@ $^

$(LIB_ABR): $(OBJS_ABR)
	${CC} -shared ${CFLAGS} ${LIBS} $^ -o $@

$(STATIC_ENC): $(OBJS_ENC)
	${AR} rcs $@ $^

$(LIB_ENC): $(OBJS_ENC)
	$(CC) -shared $(CFLAGS) $(LIBS) $^ -o $@

%.o: %.c
	$(CC) -fPIC $(CFLAGS) $(INCLUDES) -c -o $@ $<

.PHONY: clean
clean:
	$(RM) $(STATIC_ABR) $(LIB_ABR) $(OBJS_ABR) $(STATIC_ENC) $(LIB_ENC) $(OBJS_ENC)

.PHONY: install
install: all
	install -d $(DESTDIR)$(PREFIX)$(LIBDIR)
	install -m 755 $(LIB_ABR) $(LIB_ENC) $(DESTDIR)$(PREFIX)$(LIBDIR)
	install -m 644 $(STATIC_ABR) $(STATIC_ENC) $(DESTDIR)$(PREFIX)$(LIBDIR)
	install -d $(DESTDIR)$(PREFIX)$(INCLUDEDIR)
	install -m 644 $(foreach h, $(INCLUDEFILES),$(wildcard $(h)/*)) $(DESTDIR)$(PREFIX)$(INCLUDEDIR)

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PREFIX)$(LIBDIR)/$(LIB_ABR)
	rm -f $(DESTDIR)$(PREFIX)$(LIBDIR)/$(LIB_ENC)
	rm -f $(DESTDIR)$(PREFIX)$(LIBDIR)/$(STATIC_ABR)
	rm -f $(DESTDIR)$(PREFIX)$(LIBDIR)/$(STATIC_ENC)
	rm -f $(foreach file, $(foreach h, $(INCLUDEFILES),$(wildcard $(h)/*)), $(DESTDIR)$(PREFIX)$(INCLUDEDIR)/$(notdir $(file)))
