/*-
 * Copyright (c) 2010, 2011 FUKAUMI Naoki.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <sys/mman.h>
#include <sys/stat.h>
#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void
write_image(const char *path, uint8_t *buf, uint32_t size)
{
	int fd;

	if ((fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644)) == -1 ||
	    write(fd, buf, size) == -1 || close(fd) == -1)
		err(EXIT_FAILURE, "%s", path);
}

static void
unpack_krnl(const char *path, uint8_t *buf, uint32_t size)
{
	uint32_t ksize;
	char rpath[PATH_MAX];

	ksize = buf[4] | buf[5] << 8 | buf[6] << 16 | buf[7] << 24;
	buf += 8;
	size -= 8;

	if ((ksize + 4) > size)
		fprintf(stderr, "invalid file size (should be %u bytes)\n",
		    ksize);

	snprintf(rpath, sizeof(rpath), "%s-raw", path);
	write_image(rpath, buf, ksize);

	buf += ksize + 4;
	size -= ksize + 4;

	if (size > 0) {
		snprintf(rpath, sizeof(rpath), "%s-symbol", path);
		write_image(rpath, buf, size);
	}
}

static void
unpack_rkaf(const char *path, uint8_t *buf, uint32_t size)
{
	uint32_t fsize, ioff, isize, noff, nsize, h;
	uint8_t *p;
	int count;
	const char *name, *fpath, *sep;
	char dir[PATH_MAX];

	fsize = (buf[4] | buf[5] << 8 | buf[6] << 16 | buf[7] << 24) + 4;

	if (fsize != size)
		fprintf(stderr, "invalid file size (should be %u bytes)\n",
		    fsize);

	printf("FIRMWARE_VER:%d.%d.%d\n", buf[0x87], buf[0x86], buf[0x84]);
	printf("MACHINE_MODEL:%s\n", &buf[0x08]);
	printf("MACHINE_ID:%s\n", &buf[0x2a]);
	printf("MANUFACTURER:%s\n", &buf[0x48]);

	h = 0x89;
	count = buf[h] | buf[h+1] << 8 | buf[h+2] << 16 | buf[h+3] << 24;

	printf("\nunpacking %d files\n", count);
	printf("-------------------------------------------------------------------------------\n");

	for (p = &buf[h+4]; count > 0; p += 0x70, count--) {
		name = (const char *)p;
		fpath = (const char *)&p[0x20];
		nsize = p[0x5c] | p[0x5d] << 8 | p[0x5e] << 16 | p[0x5f] << 24;
		ioff = p[0x60] | p[0x61] << 8 | p[0x62] << 16 | p[0x63] << 24;
		noff = p[0x64] | p[0x65] << 8 | p[0x66] << 16 | p[0x67] << 24;
		isize = p[0x68] | p[0x69] << 8 | p[0x6a] << 16 | p[0x6b] << 24;
		fsize = p[0x6c] | p[0x6d] << 8 | p[0x6e] << 16 | p[0x6f] << 24;

		if (memcmp(fpath, "SELF", 4) == 0)
			printf("----------------- %s:%s:0x%x@0x%x (%s)", name,
			    fpath, nsize, noff, path);
		else {
			printf("%08x-%08x %s:%s", ioff, ioff + isize - 1, name,
			    fpath);

			if (noff != 0xffffffffU)
				printf(":0x%x@0x%x", nsize, noff);

			if (memcmp(name, "parameter", 9) == 0) {
				ioff += 8;
				fsize -= 12;
			}

			sep = fpath;
			while ((sep = strchr(sep, '/')) != NULL) {
				memcpy(dir, fpath, sep - fpath);
				dir[sep - fpath] = '\0';
				if (mkdir(dir, 0755) == -1 && errno != EEXIST)
					err(EXIT_FAILURE, "%s", dir);
				sep++;
			}

			write_image(fpath, &buf[ioff], fsize);
			if (memcmp(&buf[ioff], "KRNL", 4) == 0 ||
			    memcmp(&buf[ioff], "PARM", 4) == 0)
				unpack_krnl(fpath, &buf[ioff], fsize);
		}

		printf(" %d bytes\n", fsize);
	}

	printf("-------------------------------------------------------------------------------\n");
}

static void
unpack_rkfw(const char *path, uint8_t *buf, uint32_t size)
{
	uint32_t ioff, isize;
	char rpath[PATH_MAX];

	printf("VERSION:%d.%d.%d\n", buf[8], buf[7], buf[6]);
	printf("\nunpacking\n");

	ioff = 0;
	isize = buf[4];
	snprintf(rpath, sizeof(rpath), "%s-HEAD", path);
	printf("%08x-%08x %s %d bytes\n", ioff, ioff + isize - 1, rpath, isize);
	write_image(rpath, &buf[ioff], isize);

	ioff = buf[0x19] | buf[0x1a] << 8 | buf[0x1b] << 16 | buf[0x1c] << 24;
	isize = buf[0x1d] | buf[0x1e] << 8 | buf[0x1f] << 16 | buf[0x20] << 24;

	if (memcmp(&buf[ioff], "BOOT", 4) != 0)
		errx(EXIT_FAILURE, "no BOOT signature");

	snprintf(rpath, sizeof(rpath), "%s-BOOT", path);
	printf("%08x-%08x %s %d bytes\n", ioff, ioff + isize - 1, rpath, isize);
	write_image(rpath, &buf[ioff], isize);

	ioff = buf[0x21] | buf[0x22] << 8 | buf[0x23] << 16 | buf[0x24] << 24;
	isize = buf[0x25] | buf[0x26] << 8 | buf[0x27] << 16 | buf[0x28] << 24;

	if (memcmp(&buf[ioff], "RKAF", 4) != 0)
		errx(EXIT_FAILURE, "no RKAF signature");

	printf("%08x-%08x update.img %d bytes\n", ioff, ioff + isize - 1,
	    isize);
	write_image("update.img", &buf[ioff], isize);

	printf("\nunpacking update.img\n");
	printf("================================================================================\n");
	unpack_rkaf("update.img", &buf[ioff], isize);
	printf("================================================================================\n\n");

	if (size - (ioff + isize) != 32)
		errx(EXIT_FAILURE, "invalid MD5 length");

	snprintf(rpath, sizeof(rpath), "%s-MD5", path);
	printf("%08x-%08x %s 32 bytes\n", ioff, ioff + isize - 1, rpath);
	write_image(rpath, &buf[ioff + isize], 32);
}

int
main(int argc, char *argv[])
{
	off_t size;
	uint8_t *buf;
	int fd;

	if (argc != 2) {
		fprintf(stderr, "usage: %s image\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	if ((fd = open(argv[1], O_RDONLY)) == -1)
		err(EXIT_FAILURE, "%s", argv[1]);

	if ((size = lseek(fd, 0, SEEK_END)) == -1)
		err(EXIT_FAILURE, "%s", argv[1]);

	if ((buf = mmap(NULL, size, PROT_READ, MAP_SHARED | MAP_FILE, fd, 0))
	    == MAP_FAILED)
		err(EXIT_FAILURE, "%s", argv[1]);

	if (memcmp(buf, "RKFW", 4) == 0)
		unpack_rkfw(argv[1], buf, size);
	else if (memcmp(buf, "RKAF", 4) == 0)
		unpack_rkaf(argv[1], buf, size);
	else if (memcmp(buf, "KRNL", 4) == 0 || memcmp(buf, "PARM", 4) == 0)
		unpack_krnl(argv[1], buf, size);
	else
		errx(EXIT_FAILURE, "invalid signature");

	printf("unpacked\n");

	munmap(buf, size);
	close(fd);

	return EXIT_SUCCESS;
}
