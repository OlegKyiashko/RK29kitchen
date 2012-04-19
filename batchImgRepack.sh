#!/bin/bash
#set -vx 

#settings for auto fix
mymodel="CUBE U9GT 2"
myopt="quiet"
mysystem=400
mysystemfs="ext3"
mycache=64
myuserdata=2048

usage(){
	echo Usage:
	echo    $0 path_to_image/file.img
}

if [ "x$1" == "x" ]
then
	usage
	exit 1
fi

BASEDIR=`dirname $0`
pushd "$BASEDIR"
BASEDIR=`pwd`
popd

WORKDIR=`dirname $1`
pushd "$WORKDIR"
WORKDIR=`pwd`"/"
popd

BINDIR="${BASEDIR}/bin"
LOGFILE="${BASEDIR}/log"
PLUGINS="${BASEDIR}/plugins"
PATH="${BINDIR}":$PATH
tempfile=`mktemp 2>/dev/null` || tempfile=/tmp/rk29$$

export BASEDIR WORKDIR BINDIR LOGFILE PATH tempfile PLUGINS

trap "rm -f $tempfile" 0 1 2 5 15

declare MENUITEM
declare FUNCTION

rm "${LOGFILE}"
touch "${LOGFILE}"
chmod +x "${BINDIR}/"*


for file in `ls -1 "${PLUGINS}"/[0-9][0-9]\.*\.sh`
do
	chmod +x $file
	source $file
done

cd "${WORKDIR}"
workdirTest
if [ ${WORKTYPE} -ne 4 ]
then
	usage
	exit 1
fi

#unpack img
extractExtractImgFile $1
extractExtractProcess

#parse && edit parameter file
PARAMFILE="parameter"
parameterParse
if [ ${PARAMFILEPARSED} -ne 1 ]
then
	return
fi
parameterEdit "$mymodel" "$myopt" $mysystem $mycache $myuserdata
parameterMake

resizeSystemProcess $[$mysystem-1] "$mysystemfs"

installSU
installBB
installAllAPK

makeUpdateProcess

