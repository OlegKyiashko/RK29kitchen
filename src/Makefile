CC=gcc
CPPFLAGS=-DHAS_BLKID
CPPFLAGS=-DUSE_OPENSSL
CFLAGS=-g -O3 -DUSE_OPENSSL -Wall
#-m32
LDLIBS=-lblkid
LDLIBS=-lssl -lcrypto -lusb-1.0

TARGETS := abootimg afptool img_unpack img_maker mkkrnlimg rkflashtool rkflashtool29 rkcrc pnm2clut224 to565 from565
#to565

.PHONY:	clean all install

all: ${TARGETS}

clean:
	rm -f ${TARGETS}

install:
	mv ${TARGETS} ../bin

