#!/bin/bash
set -vx 

BASEDIR=`dirname $0`
pushd "$BASEDIR"
BASEDIR=`pwd`
popd

WORKDIR=${1:-`pwd`}
pushd "$WORKDIR"
WORKDIR=`pwd`"/"
popd

if [ "${WORKDIR}" == "${BASEDIR}" ]
then
	WORKDIR="${WORKDIR}/work/"
fi

BINDIR="${BASEDIR}/bin"
LOGFILE="${BASEDIR}/log"
PLUGINS="${BASEDIR}/plugins"
PATH="${BINDIR}":$PATH

export BASEDIR WORKDIR BINDIR LOGFILE PATH PLUGINS

rm "${LOGFILE}"
touch "${LOGFILE}"
chmod +x "${BINDIR}/"*

pushd "${PLUGINS}"
for file in `ls -1 [0-9][0-9]\.*\.sh`
do
	chmod +x $file
	source $file
done
popd

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

