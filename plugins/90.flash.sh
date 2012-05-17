#!/bin/bash
#set -vx

MenuAdd "Flashing update to tablet" "flash_Main"

flash_Process(){
	pushd "$WORKDIR" 2>/dev/null

	SystemUmount

	mkparmimg

	echo "Flashing IDB"
	${SUDO} rkflashtool w 0x0 0xa0 < parm.img 2>>${LOGFILE}
	PARAMFILE="parameter"
	parameter_Parse

	sz=${#SECTION[@]}
	for (( n=0; n<${#SECTION[@]}; n++ ))
	do
		sname=${SECTION[$n]}
		ssize=${SSIZE[$n]}
		sstart=${SSTART[$n]}
		if [ "$sname" == "user" ]
		then
			continue
		fi

		cmd=`printf "rkflashtool w 0x%08x 0x%08x " ${sstart} ${ssize}`
		case $sname in
			"boot" | "kernel" | "misc" | "recovery" | "system" )
				echo "Flashing ${sname}"
				${SUDO} $cmd < Image/${sname}.img 2>>${LOGFILE}
				;;
			"backup" )
				#echo "Dumping ${sname}"
				#${SUDO} $cmd > ${sname}.img
				;;
			"cache" | "kpanic" | "userdata" )
				;;
		esac
	done
	${SUDO} rkflashtool b 2>>${LOGFILE}


	popd 2>/dev/null
}

flash_Main(){
	dialogOK "Power off you tablet.\nPress the VOL- button and connect usb cable to PC and tablet\nRelease button"

	if [ "${WORKMODE}" != "In progress" ]
	then
		dialogOK "Mode unsupported now"
		return
	fi

	if [ -z "${BOOTLOADER}" ]
	then
		bootloader_ParseBL
	fi

	${SUDO} rkflashtool r 0x0 0xa0 >"$tempfile"
	s=$(stat -c%s "$tempfile")
	if [ $s -ne 81920 ]
	then
		dialogOK "Tablet is not ready"
		return
	fi
	dialogYN "The tablet firmware will be flashed. Exit?"
	case $? in
		0)
			return
			;;
	esac

	#flash_Process
}
