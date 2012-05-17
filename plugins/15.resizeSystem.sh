#!/bin/bash
#set -vx

MenuAdd "Resize system.img (/system partition)" "resizeSystem_Menu"

resizeSystem_Process(){
	sz=$1
	fs=$2

	SystemMount
	pushd Image 2>> "${LOGFILE}"
	dd if=/dev/zero of=system.new bs=1M count=${sz} 2>> "${LOGFILE}"
	mkfs -t ${fs} -F -L system -m 0 system.new  2>> "${LOGFILE}"
	mkdir system1  2>> "${LOGFILE}"
	${SUDO} mount system.new system1 2>> "${LOGFILE}"
	cd system 2>> "${LOGFILE}"
	${SUDO} tar cf - * | sudo tar xvf - -C ../system1 2>> "${LOGFILE}"
	r=$?
	cd ..
	SystemUmount
	${SUDO} umount -f system1 2>> "${LOGFILE}"
	rm -rf system1

	if [ $r -ne 0 ]
	then
		dialogLOG "Resize process has errors"
	else
		BackupFile system.img
		mv system.new system.img  2>> "${LOGFILE}"
	fi
	SystemMount
	popd 2>> "${LOGFILE}"
}

resizeSystem_ProcessDlg(){
	sz=$1
	sz=$[${sz}-1]
	ftype=`file Image/system.img`
	fs="ext3"

#	dialogBT
#	dialog --colors --backtitle "${DIALOGBT}" --title "Resize system.img (/system partition)" \
#		--menu "Old system.img is: ${ftype}\nSelect new system.img fs type:" 20 70 10 \
#		"ext3" "Use fs type ext3"\
#		"ext4" "Use fs type ext4"\
#		"X" "Exit" 2>$tempfile
#	case $? in
#		0)
#			fs=`cat $tempfile`
#			if [ "${fs}" == "X" ]
#			then
#				return
#			fi
#			;;
#	esac

	dialogYN "New file fs: ${fs}\nNew size: ${sz}MB(1MB will reserved)\nResize system.img file?"
	case $? in
		0)
			;;
		*)
			return
			;;
	esac

	dialogINF "Resizing in process. Please wait..."

	resizeSystem_Process $sz $fs
}

resizeSystem_ByParameter(){
	if [ ${PARAMFILEPARSED} -eq 0 ]
	then
		parameter_FileSelect
	fi

	if [ ${PARAMFILEPARSED} -eq 0 ]
	then
		return
	fi

	for (( n=0; n<${#SECTION[@]}; n++ ))
	do
		name=${SECTION[$n]}
		ssize=${SSIZE[$n]}
		if [ $name == "system" ]
		then
			bsize=$[$ssize/2048]
			resizeSystem_ProcessDlg ${bsize}
			break
		fi
	done
}

resizeSystem_ByValue(){
	sz=`stat -c%s Image/system.img`
	sz=$[${sz}/1024/1024+1]
	dialogBT
	dialog --colors --backtitle "${DIALOGBT}" --title "Resize system.img (/system partition)" \
		--inputbox "Set size of the \Z1system\Zn partition.\nOld size: ${sz}MB\nNew size (MB) (1MB will reserved):" 10 70 "$sz" 2> $tempfile
	case $? in
		0)
			bsize=`cat $tempfile`
			resizeSystem_ProcessDlg ${bsize}
			;;
	esac
}

resizeSystem_UpdateParameter(){
	sz=`stat -c%s Image/system.img`
	sz=$[${sz}/1024/1024+1]

	if [ ${PARAMFILEPARSED} -eq 0 ]
	then    
		parameter_FileSelect
	fi      

	if [ ${PARAMFILEPARSED} -eq 0 ]
	then    
		return  
	fi      

	for (( n=0; n<${#SECTION[@]}; n++ ))
	do      
		name=${SECTION[$n]}
		ssize=${SSIZE[$n]}
		if [ $name == "system" ]
		then    
			sz=$[$sz*2048]
			SSIZE[$n]=`printf 0x%08x $sz`
			break   
		fi      
	done

	dialogYN "Save new ${PARAMETER} file?"
	case $? in
		0)
			parameter_Make
			;;
		*)
			PARAMFILEPARSED=0
			PARAMFILE=""
			;;
	esac

}

resizeSystem_Menu(){
	if [ "${WORKMODE}" != "In progress" ] 22 [ "${WORKMODE}" != "Image" ]
	then
		dialogOK "You should extract image files before continue..."
		return
	fi
	while [ true ]
	do
		dialogBT
		dialog --colors --backtitle "${DIALOGBT}" --title "Resize system.img (/system partition)" \
			--menu "Select:" 20 70 15 \
			"P" "Use size from file 'parameter'"\
			"S" "Set value"\
			"U" "Update file 'parameter' by system.img file size" \
			"X" "Exit" 2>$tempfile
		case $? in
			0)
				s=`cat $tempfile`
				case $s in
					"P")
						resizeSystem_ByParameter
						;;
					"S")
						resizeSystem_ByValue
						;;
					"U")
						resizeSystem_UpdateParameter
						;;
					"X")
						return
						;;
				esac
				;;
			*)
				return
				;;
		esac
	done
}

