#!/bin/bash
#set -vx

MenuAdd "Parse parameter file" "parameterParse"
MenuAdd "Edit parameter file" "parameterEdit"
MenuAdd "Make new parameter file" "parameterMake"

declare SECTION
declare SSIZE
MODEL="CUBE U9GT 2"

parameterParse() {
	if [ -f "parameter" ]
	then
		PARAMFILE="parameter"
	elif [ -f "parameter1G" ]
	then
		PARAMFILE="parameter1G"
	else
		dialog --msgbox "File parameter(1G) does not exist" 5 50
		return	
	fi

	CMDLINE=`grep CMDLINE ${PARAMFILE}`

	REGEXP="(^CMDLINE.*mtdparts=rk29xxnand:)(.*)$"

	if [[ "${CMDLINE}" =~ ${REGEXP} ]]
	then
		CMDPRE=${BASH_REMATCH[1]}
		PARTS=${BASH_REMATCH[2]}
	else
		dialog --msgbox "Ill-formed config line" 5 50
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
			dialogMSG 'Ill-formed config line'
		fi
		SECTION[$n]=$sname
		SSIZE[$n]=$ssize
		n=$[n+1]
	done
	parameterInfo >${PARAMFILE}.info
}

parameterEdit(){
	if [ "x${CMDLINE}" == "x" ]
	then
		dialogMSG "Param file don't parsed before"
		return
	fi

	dialogYN "Quiet boot mode?"
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
		if [ $ssize != '-' ]
		then

			bsize=$[$ssize/2048]
			dialog --colors --title "Resize partitions" \
				--inputbox "Change size of the \Z1$name\Zn partition.\nCurrent value is \Z1${bsize}MB\Zn (${ssize} blocs)\nNew value (MB):" 10 50 ${bsize} 2> $tempfile

			case $? in
				0)
					s=`cat $tempfile`
					s=$[s*2048]
					SSIZE[$n]=`printf 0x%08x $s`
					;;
			esac
		fi
	done
	parameterInfo >${PARAMFILE}.new.info
}

parameterInfo(){
	if [ "x${CMDLINE}" == "x" ]
	then
		dialogMSG "Param file don't parsed before"
		return
	fi

	for (( n=0; n<${#SECTION[@]}; n++ ))
	do
		name=${SECTION[$n]}
		ssize=${SSIZE[$n]}
		if [ $ssize != '-' ]
		then
			bsize=$[$ssize/2048]
		else
			bsize='-'
		fi
		echo -e section:$name   size=$bsize MB     $ssize blocks
	done

}

parameterMake(){
	if [ "x${CMDLINE}" == "x" ]
	then
		dialogMSG "Param file don't parsed before"
		return
	fi

	HEADER="FIRMWARE_VER:0.2.3\nMACHINE_MODEL:$MODEL \nMACHINE_ID:007\nMANUFACTURER:RK29SDK\nMAGIC: 0x5041524B\nATAG: 0x60000800\nMACHINE: 2929\nCHECK_MASK: 0x80\nKERNEL_IMG: 0x60408000\n"
	NEWCMDLINE="CMDLINE: ${QUIET} console=ttyS1,115200n8n androidboot.console=ttyS1 init=/init initrd=0x62000000,0x800000 mtdparts=rk29xxnand:"
	#0x00002000@0x00002000(misc),0x00004000@0x00004000(kernel),0x00008000@0x00008000(boot),0x00008000@0x00010000(recovery),0x00100000@0x00018000(backup),0x00002000@0x00118000(kpanic)"

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
	echo -e ${HEADER}${NEWCMDLINE} |unix2dos>${PARAMFILE}.new
	diff -c ${PARAMFILE} ${PARAMFILE}.new >${PARAMFILE}.patch
}


