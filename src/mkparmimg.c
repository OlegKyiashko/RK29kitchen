#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include "rkcrc.h"

#define MAGIC_CODE "PARM"


struct krnl_header
{
	char magic[4];
	unsigned int length;
};

int main(int argc, char **argv)
{
	FILE *fp_in, *fp_out;
	int i;

        fp_in = fopen("parameter", "rb");
        fp_out = fopen("parm.img", "wb");

	char buf[16384];
	struct krnl_header header =
	{
		MAGIC_CODE,
		0
	};

	unsigned int crc = 0;


	int readlen = fread(buf, 1, sizeof(buf), fp_in);
	if (readlen == 0 || readlen >16380)
	return -2;

	header.length += readlen;
	RKCRC(crc, buf, readlen);

	for(i=0; i<5; i++)
	{
		fseek(fp_out, i*0x4000, SEEK_SET);
		fwrite(&header, sizeof(header), 1, fp_out);
		fwrite(buf, 1, readlen, fp_out);
		fwrite(&crc, sizeof(crc), 1, fp_out);
	}
	fseek(fp_out, i*0x4000-sizeof(i), SEEK_SET);
	i=0;
	fwrite(&i,1,sizeof(i),fp_out);
	printf("%04X\n", crc);

	return 0;
}
