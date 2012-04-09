#!/bin/bash
#set -vx

MenuAdd "Select work directory" "workdirSelect"
WORKTYPE=99
WORKMODE="Undefined"

workdirTest(){
	c=`ls -1 ${WORKDIR}/Image/zImage 2>/dev/null | wc -l `
	if [ $c -eq 1 ]
	then
		WORKTYPE=2
		WORKMODE="In progress"
		return
	fi

	c=`ls -1 ${WORKDIR}/parameter ${WORKDIR}/parameter1G ${WORKDIR}/Image/*img ${WORKDIR}/RK29xx*bin 2>/dev/null | wc -l `
	if [ $c -gt 6 ]
	then
		WORKTYPE=1
		WORKMODE="Image"
		return
	fi

	c=`ls -1 ${WORKDIR}/*img 2>/dev/null | wc -l `
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
		dialog --title "Choose work directory" --dselect "${WORKDIR}" 20 70 2> $tempfile
		case $? in
			0)
				cd `cat $tempfile`
				WORKDIR=`pwd`"/"
				workdirTest
				case $WORKTYPE in
					99)
						dialogYN "Rom files not found. Exit?"
						case $? in
							0)
								return	
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
						return	
						;;
					*)
						continue
						;;
				esac
		esac
	done
}

