#!/bin/bash
#set -vx

MenuAdd "Flashing update to tablet" "flash_Main"

flash_Process(){
	pushd "$WORKDIR" >/dev/null

	SystemUmount

	rkcrc -p parameter parm.img

#	echo "Erasing IDB"
#	${SUDO} rkflashtool29 e 0x0 0x1000
	echo "Flashing IDB"
	${SUDO} rkflashtool29 w 0x0 0x20 < parm.img
	${SUDO} rkflashtool29 w 0x20 0x20 < parm.img
	${SUDO} rkflashtool29 w 0x40 0x20 < parm.img
	${SUDO} rkflashtool29 w 0x60 0x20 < parm.img
	${SUDO} rkflashtool29 w 0x80 0x20 < parm.img
	PARAMFILE="parameter"
	parameter_Parse

	sz=${#SECTION[@]}
	for (( n=0; n<${#SECTION[@]}; n++ ))
	do
		sname=${SECTION[$n]}
		if [ "$sname" == "user" ]
		then
			continue
		fi

		ssize=${SSIZE[$n]}
		sstart=${SSTART[$n]}

		case $sname in
			"boot" | "kernel" | "misc" | "recovery" | "system" )
				fn="Image/${sname}.img"
				s=$(stat -c%s "$fn")
				s=$[($s+16384)/512]
				s=$(printf 0x%08x $s)
				#echo $ssize" "$s
				s=$ssize
				send=$[$sstart+$s]
				send=$(printf 0x%08x $send)
				cmd=`printf "rkflashtool29 w 0x%08x 0x%08x " ${sstart} ${s}`
				echo "Flashing ${sname} ($sstart  $send)"
				#echo $cmd
				${SUDO} $cmd < ${fn}
				;;
			"backup" )
				fn="update.img.tmp"
				s=$(stat -c%s "$fn")
				s=$[($s+16384)/512]
				s=$(printf 0x%08x $s)
				#echo $ssize" "$s
				s=$ssize
				send=$[$sstart+$s]
				send=$(printf 0x%08x $send)
				cmd=`printf "rkflashtool29 w 0x%08x 0x%08x " ${sstart} ${s}`
				echo "Flashing ${sname} ($sstart  $send)"
				#echo $cmd
				${SUDO} $cmd < ${fn}
				;;
			"cache" | "kpanic" | "userdata" )
				cmd=`printf "rkflashtool29 e 0x%08x 0x200 " ${sstart}`
				echo "Erase ${sname} ($sstart )"
				#${SUDO} $cmd
				;;
		esac
	done
	${SUDO} rkflashtool29 b


	popd >/dev/null
}

flash_Dump(){
	mkdir -p flashdump/Image 2>/dev/null
	cd flashdump
	WORKDIR=$(pwd)


	${SUDO} rkflashtool29 r 0 1 >parm.img
	mkkrnlimg -r parm.img parameter

	PARAMFILE="parameter"
	parameter_Parse

	sz=${#SECTION[@]}
	for (( n=0; n<${#SECTION[@]}; n++ ))
	do
		sname=${SECTION[$n]}
		ssize=${SSIZE[$n]}
		sstart=${SSTART[$n]}
		if [ ${sname} == "user" ]
		then
			continue
		fi
		cmd=`printf "rkflashtool29 r 0x%08x 0x%08x " ${sstart} ${ssize}`
		case $sname in
			"boot" | "kernel" | "misc" | "recovery" | "system" )
				echo "Dumping ${sname} ($cmd)"
				${SUDO} $cmd > Image/${sname}.img 2>>${LOGFILE}
				;;
			"0backup" )
				echo "Dumping ${sname} ($cmd)"
				${SUDO} $cmd > ${sname}.img 2>>${LOGFILE}
				;;
			"0cache" | "0kpanic" | "0userdata" | "0user" )
				;;
                        *)
                                echo OOPS $sname
                                ;;
		esac
	done
}

flash_Main(){
	if [ "${WORKMODE}" != "In progress" ]
	then
		dialogUnpackFW
		return
	fi

	if [ -z "${BOOTLOADER}" ]
	then
		bootloader_ParseBL
	fi

#	if [ $MADEIMAGE -eq 100 ]
#	then
#		makeUpdateImage_Process
#	fi

	dialogOK "Power off you tablet.\nPress the VOL- button and connect usb cable to PC and tablet\nRelease button"

	${SUDO} rkflashtool29 r 0x0 0xa0 >"$tempfile"
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

	flash_Process
}

