#!/bin/bash
#set -vx

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

