#!/bin/bash
#set -vx

TZ=UTC
export TZ
tempfile=`mktemp 2>/dev/null` || tempfile=/tmp/rk29$$
tempdir=`mktemp -d 2>/dev/null` || tempdir=/tmp/rk29d$$
mkdir -p $tempdir 2>/dev/null

export tempfile tempdir

trap "rm -rf $tempfile $tempdir" 0 1 2 5 15


#1 - menu title; 2-function
declare MENUITEM
declare FUNCTION
N=0
MenuAdd() {
	N=$[N+1]
	MENUITEMS="${MENUITEMS} \"$N\" \"$1\""
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

BackupFile(){
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
FileSignature(){
	fn=$1
	sigSize=${2:-4}
	COMMONFILESIGNATURE=`dd if="$1" bs=1 count=4`
}

SetDirPermissions(){
	path=$1
	uid=$2
	gid=$3
	fmod=$4
	dmod=$5
	find ${path} -type f -print0| xargs -0 sudo chmod ${fmod} 2>>${LOGFILE}
	find ${path} -type d -print0| xargs -0 sudo chmod ${dmod} 2>>${LOGFILE}
	sudo chown -R ${uid}:${gid} "${ath}" 2>>${LOGFILE}
}

SetFilePermissions(){
	fn=$1
	uid=$2
	gid=$3
	mod=$4
	sudo chmod ${mod} "$fn" 2>>"${LOGFILE}"
	sudo chown ${uid}:${gid} "$fn" 2>>"${LOGFILE}"
}

ApkLibExtract(){
	apk=$1
	APKLIBDIR="$tempdir/$apk/"
	unzip "$apk" -d "$APKLIBDIR" "*.so"
	pushd "$APKLIBDIR"
	if [ -d lib/armeabi-v7a ]
	then
		mv lib/armeabi-v7a/*.so .
	elif [ -d lib/armeabi ]
	then
		mv lib/armeabi/*.so .
	fi
	rm -rf lib 2>/dev/null
	APKLIBFILES=$(ls -1 *.so)
	popd
}

DirToArray(){
	fn="$1"
	ifs=$IFS
	IFS=$'\n'
	FILEARRAY=($(ls -1 ${fn}))
	IFS=$ifs
}

FileToArray(){
	fn="$1"
	ifs=$IFS
	IFS=$'\n'
	FILEARRAY=( `cat $fn|sed -e 's/" *"/\n/g'|sed -e 's/"//g'` )
	IFS=$ifs
}

# ListCheckboxDlg "" FILEARRAY[@] "Install" "Choose files:"
ListCheckboxDlg(){
	listOn=("${!1}")
	listOff=("${!2}")
	titletxt="$3"
	headertxt="$4"
	lst=""
	if [ ! -z "${listOn[0]}" ]
	then
		listsize=${#listOn[@]}
		for (( i=0; i<${listsize}; i++ ))
		do
			f=${listOn[$i]}
			lst="${lst} \"${f}\" \"\" on"
		done
	fi
	if [ ! -z "${listOff[0]}" ]
	then

		listsize=${#listOff[@]}
		for (( i=0; i<${listsize}; i++ ))
		do
			f=${listOff[$i]}
			lst="${lst} \"${f}\" \"\" off"
		done
	fi
	if [ ! -z "${lst}" ]
	then

		dialogBT
		echo $lst|xargs dialog --colors --backtitle "${DIALOGBT}" --separate-output --title "$titletxt" --checklist "$headertxt" 20 70 15 2>$tempfile
		r=$?
		FileToArray "$tempfile"
	else
		dialogOK "Empty list"
		r=1
	fi
	return $r
}

# FilesMenuDlg "*.img" "Extract img file" "Choose file:" 
FilesMenuDlg(){
	fn="$1"
	titletxt="$2"
	headertxt="$3"
	DirToArray "${fn}"
	n=${#FILEARRAY[@]}
	for (( i=0; i<${n}; i++ ))
	do
		f=${FILEARRAY[$i]}
		lst="${lst} \"${f}\" \"\""
	done

	dialogBT
	echo $lst | xargs dialog --colors --backtitle "${DIALOGBT}" --title "$titletxt" --menu "$headertxt" 20 70 15 2>$tempfile
	r=$?
	FileToArray "$tempfile"
	return $r
}

