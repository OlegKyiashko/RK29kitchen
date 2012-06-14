fn=jhonxie.abootimg_rockchip.zip
rm $fn 2>/dev/null
wget https://github.com/jhonxie/abootimg_rockchip/zipball/master -O $fn
unzip -jo $fn "*/abootimg.c" "*/bootimg.h"

fn=jhonxie.rk2918_tools.zip
rm $fn 2>/dev/null
wget https://github.com/jhonxie/rk2918_tools/zipball/master -O $fn
unzip -jo $fn "*/afptool.c" "*/img_maker.c" "*/img_unpack.c" "*/md5.h" "*/mkkrnlimg.c" "*/rkafp.h" "*/rkrom_29xx.h" "*/rkcrc.h"

fn=naobsd.rkutils.zip
rm $fn 2>/dev/null
wget https://github.com/naobsd/rkutils/zipball/master -O $fn
#unzip -jo $fn "*/rkcrc*"

svn export --force https://rkflashtool.svn.sourceforge.net/svnroot/rkflashtool/trunk/rkflashtool.c

#patch <rkflashtool.patch

make clean all install
