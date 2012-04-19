#!/bin/bash
#set -vx

#1 - menu title; 2-function
declare MENUITEM
declare FUNCTION
N=0
MenuAdd() {
	N=$[N+1]
	MENUITEM[$N]="\"$N\" \"$1\""
	FUNCTION[$N]="$2"
}

dialogBT(){
	DIALOGBT="Work dir: \Z1${WORKDIR}\Zn Mode:\Z2${WORKMODE}\Zn Parameter file:\Z3${PARAMFILE}\Zn" 
}

dialogINF(){
	dialogBT
	dialog --colors --backtitle "${DIALOGBT}" --infobox "$1" 8 70
}

dialogOK(){
	dialogBT
	dialog --colors --backtitle "${DIALOGBT}" --msgbox "$1" 8 70
}

dialogYN(){
	dialogBT
	dialog --colors --backtitle "${DIALOGBT}" --yesno "$1" 8 70
}

dialogLOG(){
	dialogBT
	dialog --colors --backtitle "${DIALOGBT}" --msgbox "$1" 8 70
	dialog --colors --backtitle "${DIALOGBT}" --title "Show log" --textbox ""${LOGFILE}"" 20 70
}

pressEnterToContinue(){
	echo -n "Press Enter to continue..."
	read a
}

commonBackupFile(){
	fn="$1"
	s="#"

	if [ ! -f "$fn" ]
	then
		echo File $fn not found
		return
	fi

	old="${fn}"
	while [ true ]
	do
		old="${old}${s}"
		if [ -f "${old}" ]
		then
			continue
		fi
		cp "${fn}" "${old}"
		COMMONBACKUPFILE="${old}"
		break
	done
}

# first 4 bytes of file. 'ANDR' or 'KRNL' for android img files 
commonFileSignature(){
	fn=$1
	sigSize=${2:-4}
	COMMONFILESIGNATURE=`dd if="$1" bs=1 count=4`
}
