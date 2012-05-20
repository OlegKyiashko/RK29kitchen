#!/bin/bash
set -vx 

#settings for auto fix
mymodel="CUBE U9GT 2"
myopt="quiet"
mysystem=400
mysystemfs="ext3"
mycache=64
myuserdata=2048

usage(){
	echo Usage:
	echo    $0 path_to_image_directory
}

BASEDIR=`dirname $0`
pushd "$BASEDIR"
BASEDIR=`pwd`
popd

WORKDIR=${1:-`pwd`}
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
workdir_Test
if [ ${WORKTYPE} -ne 1 ]
then
	usage
	exit 1
fi

#unpack 
extractImage_ExtractImage

#parse && edit parameter file
PARAMFILE="parameter"
parameter_Parse
if [ ${PARAMFILEPARSED} -ne 1 ]
then
	return
fi
parameter_Edit "$mymodel" "$myopt" $mysystem $mycache $myuserdata
parameter_Make

resizeSystem_Process $[$mysystem-1] "$mysystemfs"

installApps_SU
installApps_BB
installApps_RemoveAllApk
installApps_InstallAllApk

SetBuildProp "ro.product.locale.language" "uk"
SetBuildProp "ro.product.locale.region" "UA"
SetBuildProp "ro.com.android.dateformat" "yyyy/MM/dd"
SetBuildProp "wifi.supplicant_scan_interval" "300"

echo You can make changes manually now.
echo -n Make update.img y/n [y]?
read a
case "$a" in
	"y"|"Y"|"")
		makeUpdateImage_Process
		;;
esac
#WORKDIR="../work/"
