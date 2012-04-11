#!/bin/bash
#set -vx

MenuAdd "Resize system.img (/system partition)" "resizeSystemMenu"

resizeSystemMenu(){
	dialogBT
	dialog --colors --backtitle "${DIALOGBT}" --title "Resize system.img (/system partition)" \
		--menu "Select:" 20 70 10 \
		"P" "Use size from file 'parameter'"\
		"S" "Set value"\
		"U" "Update file 'parameter' by system.img file size" \
		"X" "Exit" 2>$tempfile


	while [ true ]
	do
		parameterFileSelect

		if [ PARAMFILEPARSED -ne 0 ]
		then
			break
		fi
		dialogYN "Parameter file is not selected or incorrect. Exit?"
		case $? in
			0)
				return
				;;
			*)
				continue
				;;
		esac
	done
}
