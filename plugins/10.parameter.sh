#!/bin/bash
#set -vx

MenuAdd "Select parameter file" "parameterFileSelect"
MenuAdd "Edit parameter file" "parameterMenu"

declare SECTION
declare SSIZE
MODEL="CUBE U9GT 2"
PARAMFILEPARSED=0

parameterParse() {

	MODEL=`grep MACHINE_MODEL ${PARAMFILE}|cut -d: -f2|tr -d "\n\r"`
	CMDLINE=`grep CMDLINE ${PARAMFILE}|tr -d "\n\r"`
	PARTS=`grep CMDLINE ${PARAMFILE}|cut -d: -f3|tr -d "\n\r"`

	if [ -z "${CMDLINE}" ] || [ -z "${MODEL}" ]
	then
		dialogOK "Ill-formed config line"
		return
	fi

	regex=" (quiet) "
	if [[ "${CMDLINE}" =~ ${regex} ]]
	then
		QUIET=${BASH_REMATCH[1]}
	fi

	PARTS=(${PARTS//,/ })

	n=0
	REGEX1="(0x[0-9a-fA-F]*)@0x[0-9a-fA-F]*\(([a-z]*)\)"
	REGEX2="-@0x[0-9a-fA-F]*\(([a-z]*)\)"
	for PART in "${PARTS[@]}"
	do
		if [[ "${PART}" =~ ${REGEX1} ]]
		then
			ssize=${BASH_REMATCH[1]}
			sname=${BASH_REMATCH[2]}
		elif [[ "${PART}" =~ ${REGEX2} ]]
		then
			ssize='-'
			sname=${BASH_REMATCH[1]}
		else
			dialogOK 'Ill-formed config line'
		fi
		SECTION[$n]=$sname
		SSIZE[$n]=$ssize
		n=$[n+1]
	done
	PARAMFILEPARSED=1
}

parameterEditDlg(){
	dialogBT
	dialog --colors --backtitle "${DIALOGBT}" --title "Edit parameter file"  \
		--menu "Current MACHINE_MODEV value is \Z1${MODEL}\Zn\nNew value:" 20 70 10 \
		"${MODEL}"  "" "CUBE U9GT 2 "  "" "N90 " "" "LR97A01" "" 2> $tempfile
	case $? in
		0)
			NEWMODEL=`cat $tempfile`
			;;
	esac

	dialogYN "Quiet boot mode: ${QUIET}\n Enable quiet boot mode?"
	case $? in
		0)
			QUIET='quiet'
			;;
		*)
			QUIET=''
			;;
	esac

	for (( n=0; n<${#SECTION[@]}; n++ ))
	do
		name=${SECTION[$n]}
		ssize=${SSIZE[$n]}

		if [ "$ssize" != '-' ]
		then
			if [ "$name" == "system" ] || [ "$name" == "cache" ] || [ "$name" == "userdata" ]
			then
				bsize=$[$ssize/2048]
				dialogBT
				dialog --colors --backtitle "${DIALOGBT}" --title "Edit parameter file" \
					--inputbox "Change size of the \Z1$name\Zn partition.\nCurrent value is \Z1${bsize}MB\Zn (${ssize} blocs)\nNew value (MB):" 10 70 ${bsize} 2> $tempfile

				case $? in
					0)
						s=`cat $tempfile`
						s=$[$s*2048]
						SSIZE[$n]=`printf 0x%08x $s`
						;;
				esac
			fi
		fi
	done
	PARAMFILEPARSED=2
}

#args 1:model name 2: "quiet"|"" 3: system patition size in MB 4: cache size 5: userdata size
parameterEdit(){
	NEWMODEL=$1
	QUIET=$2

	for (( n=0; n<${#SECTION[@]}; n++ ))
	do
		name=${SECTION[$n]}
		ssize=${SSIZE[$n]}
		s=0
		case $name in
			"system")
				s=$3
				;;
			"cache")
				s=$4
				;;
			"userdata")
				s=$5
				;;
		esac
		if [ $s -ne 0 ]
		then
			s=$[$s*2048]
			SSIZE[$n]=`printf 0x%08x $s`
		fi
	done


}
parameterMake(){
	NEWCMDLINE="CMDLINE: ${QUIET} console=ttyS1,115200n8n androidboot.console=ttyS1 init=/init initrd=0x62000000,0x800000 mtdparts=rk29xxnand:"
	sstart="0x00002000"
	c=""
	for (( n=0; n<${#SECTION[@]}; n++ ))
	do
		name=${SECTION[$n]}
		ssize=${SSIZE[$n]}
		if [ $ssize != '-' ]
		then
			a=`printf "${c}0x%08x@0x%08x(%s)" ${ssize} ${sstart} ${name}`
			sstart=$[${sstart}+${ssize}]
			c=','
		else
			a=`printf ",-@0x%08x(%s)" ${sstart} ${name}`
		fi
		NEWCMDLINE=${NEWCMDLINE}$a
	done
	commonBackupFile "${PARAMFILE}"
	cat "${COMMONBACKUPFILE}"|sed -e "/MACHINE_MODEL/s|${MODEL}|${NEWMODEL}|" | sed -e "/CMDLINE/s|${CMDLINE}|${NEWCMDLINE}|" > "${PARAMFILE}"
	diff -c ${PARAMFILE} ${COMMONBACKUPFILE} >${PARAMFILE}.patch
}

parameterFileSelect(){
	while [ true ]
	do
		dialogBT
		dialog --colors --backtitle "${DIALOGBT}" --title "Select parameter file" --fselect "${WORKDIR}" 20 70 2>$tempfile
		case $? in
			0)
				PARAMFILE=`cat $tempfile`
				parameterParse
				;;
		esac
		if [ ${PARAMFILEPARSED} -ne 0 ]
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

parameterMenu(){
	if [ "${WORKMODE}" != "In progress" ] && [ "${WORKMODE}" != "Image" ]
	then
		dialogOK "You should extract image files before continue..."
		return
	fi

	if [ ${PARAMFILEPARSED} -eq 0 ]
	then
		parameterFileSelect
	fi

	if [ ${PARAMFILEPARSED} -eq 0 ]
	then
		return
	fi

	parameterEditDlg

	dialogYN "Save new ${PARAMETER} file?"
	case $? in
		0)
			parameterMake
			;;
		*)
			PARAMFILEPARSED=0
			PARAMFILE=""
			;;
	esac
}

