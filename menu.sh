#!/bin/bash
set -vx 

BASEDIR=`dirname $0`
if [ "$BASEDIR" == '.' ]
then
	BASEDIR=`pwd`
fi

WORKDIR=${1:-`pwd`}
if [ "$WORKDIR" == '.' ] || [ "${WORKDIR}" == "${BASEDIR}" ]
then
	WORKDIR=`pwd`"/work/"
fi

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


#1 - menu title; 2-function
N=0
MenuAdd() {
	N=$[N+1]
	MENUITEM[$N]="\"$N\" \"$1\""
	FUNCTION[$N]="$2"
}

for file in `ls -1 "${PLUGINS}"/[0-9][0-9]\.*\.sh`
do
        chmod +x $file
	source $file
done

MenuAdd "Exit" "exit 0"

cd "${WORKDIR}"
workdirTest
if [ ${WORKTYPE} -eq 99 ]
then
	workdirSelect
fi

while [ true ]
do
	dialogBT
	echo ${MENUITEM[@]}|xargs dialog --colors --backtitle "${DIALOGBT}" --title 'RK29xx toolkit' --menu "Select command" 20 70 15 2> $tempfile
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

