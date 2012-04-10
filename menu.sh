#!/bin/bash

export BASEDIR=`dirname $0`
if [ $BASEDIR == '.' ]
then
        BASEDIR=`pwd`
fi

export BINDIR=${BASEDIR}/bin
export WORKDIR=${1:-`pwd`"/"}

cd ${WORKDIR}

export PATH=${BINDIR}:$PATH

export tempfile=`mktemp 2>/dev/null` || tempfile=/tmp/rk29$$
trap "rm -f $tempfile" 0 1 2 5 15

declare MENUITEM
declare FUNCTION
N=0

#1 - menu title; 2-function
MenuAdd() {
	N=$[N+1]
	MENUITEM[$N]="\"$N\" \"$1\""
	FUNCTION[$N]="$2"
}

dialogMSG(){
	dialog --msgbox "$1" 8 70
}

dialogYN(){
	dialog --yesno "$1" 8 70
}

pressEnterToContinue(){
	echo -n "Press Enter to continue..."
	read a
}

for file in ${BASEDIR}/plugins/[0-9][0-9]\.*\.sh
do
	source $file
done

MenuAdd "Exit" "exit 0"

workdirTest
if [ ${WORKTYPE} -eq 99 ]
then
	workdirSelect
fi

while [ true ]
do
	echo ${MENUITEM[@]}|xargs dialog --title 'RK29xx toolkit' --menu "Work dir: ${WORKDIR}\nMode:${WORKMODE}\nSelect command" 20 70 10 2> $tempfile
	case $? in
		0)
			s=`cat $tempfile`
			${FUNCTION[$s]}
			;;
		*)
			break
			;;
	esac
        #pressEnterToContinue
done

