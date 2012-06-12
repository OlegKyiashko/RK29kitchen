CC=gcc
CPPFLAGS=-DHAS_BLKID
CPPFLAGS=-DUSE_OPENSSL
CFLAGS=-g -O3 -DUSE_OPENSSL -Wall
LDLIBS=-lblkid
LDLIBS=-lssl -lcrypto -lusb-1.0

TARGETS := abootimg afptool img_unpack img_maker mkkrnlimg rkflashtool to565 rkcrc

.PHONY:	clean all install

all: ${TARGETS}

clean:
	rm -f ${TARGETS}

install:
	mv ${TARGETS} ../bin

