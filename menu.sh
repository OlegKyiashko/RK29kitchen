#!/bin/bash
#set -vx 

command -v dialog >/dev/null 2>&1 || { echo >&2 "dialog required, but it's not installed.  Aborting."; exit 1; }
command -v cpio >/dev/null 2>&1 || { echo >&2 "cpio required, but it's not installed.  Aborting."; exit 1; }
command -v zip >/dev/null 2>&1 || { echo >&2 "zip required, but it's not installed.  Aborting."; exit 1; }
command -v zcat >/dev/null 2>&1 || { echo >&2 "zcat required, but it's not installed.  Aborting."; exit 1; }

BASEDIR=`dirname $0`
pushd "$BASEDIR" >/dev/null
BASEDIR=`pwd`
popd >/dev/null

WORKDIR=${1:-`pwd`}
pushd "$WORKDIR" >/dev/null
WORKDIR=`pwd`"/"
popd >/dev/null

if [ "${WORKDIR}" == "${BASEDIR}" ]
then
	WORKDIR="${WORKDIR}/work/"
fi

OS=`uname -o`
if [ "${OS}" == "Cygwin" ]
then
        BINDIR="${BASEDIR}/win"
else
        BINDIR="${BASEDIR}/bin"
fi

LOGFILE="${BASEDIR}/log"
PLUGINS="${BASEDIR}/plugins"
PATH="${BINDIR}":$PATH

export BASEDIR WORKDIR BINDIR LOGFILE PATH PLUGINS

rm "${LOGFILE}" 2>/dev/null
touch "${LOGFILE}"
chmod +x "${BINDIR}/"*

pushd "${PLUGINS}" >/dev/null
for file in `ls -1 [0-9][0-9]\.*\.sh`
do
	chmod +x $file
	source $file
done
popd >/dev/null

pushd "${BINDIR}" >/dev/null
for file in `ls -1`
do
	chmod +x $file
done
popd >/dev/null

command -v abootimg >/dev/null 2>&1 || { echo >&2 "bin/abootimg required, but it's not installed.  Aborting."; exit 1; }
command -v afptool >/dev/null 2>&1 || { echo >&2 "bin/afptool required, but it's not installed.  Aborting."; exit 1; }
command -v img_maker >/dev/null 2>&1 || { echo >&2 "bin/img_maker required, but it's not installed.  Aborting."; exit 1; }
command -v img_unpack >/dev/null 2>&1 || { echo >&2 "bin/img_unpack required, but it's not installed.  Aborting."; exit 1; }
command -v mkkrnlimg >/dev/null 2>&1 || { echo >&2 "bin/mkkrnlimg required, but it's not installed.  Aborting."; exit 1; }
command -v rkcrc >/dev/null 2>&1 || { echo >&2 "bin/rkcrc required, but it's not installed.  Aborting."; exit 1; }
command -v rkflashtool29 >/dev/null 2>&1 || { echo >&2 "bin/rkflashtool29 required, but it's not installed.  Aborting."; exit 1; }

MenuAdd "Exit" "exit 0"

cd "${WORKDIR}"
workdir_Test
if [ ${WORKTYPE} -eq 99 ]
then
	workdir_Select
fi

while [ true ]
do
	dialogBT
	echo $MENUITEMS|xargs dialog --colors --backtitle "${DIALOGBT}" --title 'RK29xx toolkit' --menu "Select command" 20 70 15 2> $tempfile
	case $? in
		0)
			s=`cat $tempfile`
			${FUNCTION[$s]}
			;;
		*)
			break
			;;
	esac
	pressEnterToContinue
done

