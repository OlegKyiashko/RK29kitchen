#!/bin/bash
export BASE_DIR=`dirname $0`
export PATH=${BASE_DIR}/bin:$PATH

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
	dialog --msgbox "$1" 5 50
}

dialogYN(){
	dialog --yesno "$1" 5 50
}

for file in ${BASE_DIR}/plugins/[0-9][0-9]\.*\.sh
do
	source $file
done

MenuAdd "Exit" "exit 0"

while [ true ]
do
	echo ${MENUITEM[@]}|xargs dialog --title 'RK29xx ROM kitchen' --menu 'Select command' 15 50 7 2> $tempfile
	case $? in
		0)
			s=`cat $tempfile`
			echo $s ${FUNCTION[$s]} >ss
			${FUNCTION[$s]}
			;;
		*)
			break
			;;
	esac
        echo -n "Press Enter to continue..."
        read a
done
