#!/bin/bash
#set -vx

MenuAdd "Select work directory" "workdirSelect"
WORKTYPE=99
WORKMODE="Undefined"

workdirTest(){
	cd "${WORKDIR}"

	c=`ls -1 Image/zImage 2>/dev/null | wc -l `
	if [ $c -eq 1 ]
	then
		WORKTYPE=2
		WORKMODE="In progress"
		return
	fi

	c=`ls -1 parameter parameter1G Image/*img RK29xx*bin 2>/dev/null | wc -l `
	if [ $c -gt 6 ]
	then
		WORKTYPE=1
		WORKMODE="Image"
		return
	fi

	c=`ls -1 *img 2>/dev/null | wc -l `
	if [ $c -gt 0 ]
	then
		WORKTYPE=4
		WORKMODE="*img file"
		return
	fi

	#fail
	WORKTYPE=99
	WORKMODE="Undefined"
	return
}

workdirSelect(){
	while [ true ]
	do
		dialogBT
		dialog --colors --backtitle "${DIALOGBT}" --title "Choose work directory" --dselect "${WORKDIR}" 20 70 2> $tempfile
		case $? in
			0)
				WORKDIR=`cat $tempfile`"/"
				cd "${WORKDIR}"
				workdirTest
				case $WORKTYPE in
					99)
						dialogYN "Rom files not found. Exit?"
						case $? in
							0)
								exit 2
								;;
							*)
								continue
								;;
						esac
						exit 1
				esac
				break
				;;
			*)
				dialogYN "Workdir not selected. Exit?"
				case $? in
					0)
						exit 1
						;;
					*)
						continue
						;;
				esac
		esac
	done
}

