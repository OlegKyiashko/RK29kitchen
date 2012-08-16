pngtopam.exe -plain %1 >logo.pnm
pnmcolormap.exe 224 -plain logo.pnm >logo.map
pnmremap.exe -mapfile logo.map -plain logo.pnm > logo.pnm224
pnm2clut224.exe logo.pnm224 
