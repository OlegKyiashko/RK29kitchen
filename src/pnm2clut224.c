/*
 *  Convert a logo in ASCII PNM format to C source suitable for inclusion in
 *  the Linux kernel
 *
 *  (C) Copyright 2001-2003 by Geert Uytterhoeven <geert@linux-m68k.org>
 *
 *  2012 by onk (create only clut224 binary logodata and logoclut)
 *
 *  --------------------------------------------------------------------------
 *
 *  This file is subject to the terms and conditions of the GNU General Public
 *  License. See the file COPYING in the main directory of the Linux
 *  distribution for more details.
 */

#include <ctype.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


static const char *programname;
static const char *filename;
static const char *outputname;
static FILE *out;


#define LINUX_LOGO_CLUT224	3	/* 224 colors */

#define MAX_LINUX_LOGO_COLORS	224

struct color {
	unsigned char red;
	unsigned char green;
	unsigned char blue;
};

static const struct color clut_vga16[16] = {
	{ 0x00, 0x00, 0x00 },
	{ 0x00, 0x00, 0xaa },
	{ 0x00, 0xaa, 0x00 },
	{ 0x00, 0xaa, 0xaa },
	{ 0xaa, 0x00, 0x00 },
	{ 0xaa, 0x00, 0xaa },
	{ 0xaa, 0x55, 0x00 },
	{ 0xaa, 0xaa, 0xaa },
	{ 0x55, 0x55, 0x55 },
	{ 0x55, 0x55, 0xff },
	{ 0x55, 0xff, 0x55 },
	{ 0x55, 0xff, 0xff },
	{ 0xff, 0x55, 0x55 },
	{ 0xff, 0x55, 0xff },
	{ 0xff, 0xff, 0x55 },
	{ 0xff, 0xff, 0xff },
};


static unsigned short logo_width;
static unsigned short logo_height;
static struct color **logo_data;
static struct color logo_clut[MAX_LINUX_LOGO_COLORS];
static unsigned int logo_clutsize;

static void die(const char *fmt, ...)
	__attribute__ ((noreturn)) __attribute ((format (printf, 1, 2)));
	static void usage(void) __attribute ((noreturn));


static unsigned int get_number(FILE *fp)
{
	int c, val;

	/* Skip leading whitespace */
	do {
		c = fgetc(fp);
		if (c == EOF)
			die("%s: end of file\n", filename);
		if (c == '#') {
			/* Ignore comments 'till end of line */
			do {
				c = fgetc(fp);
				if (c == EOF)
					die("%s: end of file\n", filename);
			} while (c != '\n');
		}
	} while (isspace(c));

	/* Parse decimal number */
	val = 0;
	while (isdigit(c)) {
		val = 10*val+c-'0';
		c = fgetc(fp);
		if (c == EOF)
			die("%s: end of file\n", filename);
	}
	return val;
}

static unsigned int get_number255(FILE *fp, unsigned int maxval)
{
	unsigned int val = get_number(fp);
	return (255*val+maxval/2)/maxval;
}

static void read_image(void)
{
	FILE *fp;
	unsigned int i, j;
	int magic;
	unsigned int maxval;

	/* open image file */
	fp = fopen(filename, "r");
	if (!fp)
		die("Cannot open file %s: %s\n", filename, strerror(errno));

	/* check file type and read file header */
	magic = fgetc(fp);
	if (magic != 'P')
		die("%s is not a PNM file\n", filename);
	magic = fgetc(fp);
	switch (magic) {
		case '1':
		case '2':
		case '3':
			/* Plain PBM/PGM/PPM */
			break;

		case '4':
		case '5':
		case '6':
			/* Binary PBM/PGM/PPM */
			die("%s: Binary PNM is not supported\n"
					"Use pnmnoraw(1) to convert it to ASCII PNM\n", filename);

		default:
			die("%s is not a PNM file\n", filename);
	}
	logo_width = get_number(fp);
	logo_height = get_number(fp);

	/* allocate image data */
	logo_data = (struct color **)malloc(logo_height*sizeof(struct color *));
	if (!logo_data)
		die("%s\n", strerror(errno));
	for (i = 0; i < logo_height; i++) {
		logo_data[i] = malloc(logo_width*sizeof(struct color));
		if (!logo_data[i])
			die("%s\n", strerror(errno));
	}

	/* read image data */
	switch (magic) {
		case '1':
			/* Plain PBM */
			for (i = 0; i < logo_height; i++)
				for (j = 0; j < logo_width; j++)
					logo_data[i][j].red = logo_data[i][j].green =
						logo_data[i][j].blue = 255*(1-get_number(fp));
			break;

		case '2':
			/* Plain PGM */
			maxval = get_number(fp);
			for (i = 0; i < logo_height; i++)
				for (j = 0; j < logo_width; j++)
					logo_data[i][j].red = logo_data[i][j].green =
						logo_data[i][j].blue = get_number255(fp, maxval);
			break;

		case '3':
			/* Plain PPM */
			maxval = get_number(fp);
			for (i = 0; i < logo_height; i++)
				for (j = 0; j < logo_width; j++) {
					logo_data[i][j].red = get_number255(fp, maxval);
					logo_data[i][j].green = get_number255(fp, maxval);
					logo_data[i][j].blue = get_number255(fp, maxval);
				}
			break;
	}

	/* close file */
	fclose(fp);
}

static inline int is_black(struct color c)
{
	return c.red == 0 && c.green == 0 && c.blue == 0;
}

static inline int is_white(struct color c)
{
	return c.red == 255 && c.green == 255 && c.blue == 255;
}

static inline int is_gray(struct color c)
{
	return c.red == c.green && c.red == c.blue;
}

static inline int is_equal(struct color c1, struct color c2)
{
	return c1.red == c2.red && c1.green == c2.green && c1.blue == c2.blue;
}

static int write_hex_cnt;

static void write_hex(unsigned char byte)
{
	fputc(byte,out);
}

static void write_logo_clut224(void)
{
	unsigned int i, j, k;

	/* validate image */
	for (i = 0; i < logo_height; i++)
		for (j = 0; j < logo_width; j++) {
			for (k = 0; k < logo_clutsize; k++)
				if (is_equal(logo_data[i][j], logo_clut[k]))
					break;
			if (k == logo_clutsize) {
				if (logo_clutsize == MAX_LINUX_LOGO_COLORS)
					die("Image has more than %d colors\n"
							"Use ppmquant(1) to reduce the number of colors\n",
							MAX_LINUX_LOGO_COLORS);
				logo_clut[logo_clutsize++] = logo_data[i][j];
			}
		}

	out = fopen("logo_data", "wb");
	if (!out)
		die("Cannot create file %s: %s\n", outputname, strerror(errno));

	/* write logo data */
        write_hex((logo_width>>8)&0xff);
        write_hex((logo_width)&0xff);
        write_hex((logo_height>>8)&0xff);
        write_hex((logo_height)&0xff);
	for (i = 0; i < logo_height; i++)
		for (j = 0; j < logo_width; j++) {
			for (k = 0; k < logo_clutsize; k++)
				if (is_equal(logo_data[i][j], logo_clut[k]))
					break;
			write_hex(k+32);
		}
	fclose(out);

	out = fopen("logo_clut", "wb");
	if (!out)
		die("Cannot create file %s: %s\n", outputname, strerror(errno));

	/* write logo clut */
	write_hex_cnt = 0;
	write_hex(logo_clutsize);
	for (i = 0; i < logo_clutsize; i++) {
		write_hex(logo_clut[i].red);
		write_hex(logo_clut[i].green);
		write_hex(logo_clut[i].blue);
	}
	fclose(out);
}

static void die(const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);

	exit(1);
}

static void usage(void)
{
	die("\n"
			"Usage: %s <filename>\n"
			"\n", programname);
}

int main(int argc, char *argv[])
{
	programname = argv[0];
	filename = argv[1];

	read_image();
	write_logo_clut224();

	return 0;
}

