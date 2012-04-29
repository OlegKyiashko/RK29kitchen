#!/bin/bash
#set -vx

MenuAdd "Install system apps" "installApps_Menu"
installApps_Begin(){
	pushd Image  2>/dev/null
	sudo mount system.img system -o loop 2>>"${LOGFILE}"
	popd  2>/dev/null
}

installApps_End(){
	pushd Image  2>/dev/null
	SetDirPermissions system/app/ 0 0 0644 0755
	SetDirPermissions system/lib/ 0 0 0644 0755
	SetDirPermissions system/bin/ 0 0 0755 0755
	SetDirPermissions system/xbin/ 0 0 0755 0755
	sudo chmod +s system/xbin/su
	#	sudo umount -f system 2>>"${LOGFILE}"
	popd 2>/dev/null
}

installApps_BB(){
	installApps_Begin
	cd "$WORKDIR/Image"

	sudo cp "${PLUGINS}/installApps/bin/busybox" system/xbin/busybox 2>>"${LOGFILE}"

	for c in `cat "${PLUGINS}/installApps/bin/busybox.lst"`
	do
		dst="system/xbin/${c}"
		if [ -f "$dst" ] || [ -L "$dst" ]
		then
			sudo mv "$dst" "${dst}#"
		fi

		sudo ln -s /system/xbin/busybox ${dst} 2>>"${LOGFILE}"
	done

	installApps_End
}

installApps_SU(){
	installApps_Begin
	cd "$WORKDIR/Image"

	sudo mv system/bin/su "system/bin/su#" 2>/dev/null 
	sudo mv system/xbin/su "system/xbin/su#" 2>/dev/null

	sudo cp "${PLUGINS}/installApps/bin/su" system/xbin/su 2>>"${LOGFILE}"
	sudo cp "${PLUGINS}/installApps/bin/Superuser.apk" system/app/ 2>>"${LOGFILE}"

	installApps_End
}

installApps_ExtractSystemLibs(){
	pushd "${WORKDIR}/Image/system/app/" 2>/dev/null
	DirToArray "*.apk"
	n=${#FILEARRAY[@]}
	for (( i=0; i<${n}; i++ ))
	do
		f=${FILEARRAY[$i]}
		ApkLibExtract "$f"
		if [ ! -z "${APKLIBFILES}" ]
		then
			pushd "${APKLIBDIR}" 2>/dev/null
			sudo cp *.so "${WORKDIR}/Image/system/lib/"  2>>"${LOGFILE}"
			popd 2>/dev/null
		fi
	done
	popd 2>/dev/null
}

installApps_RemoveListApk(){
	installApps_Begin
	apklist=("${!1}")
	pushd "${WORKDIR}/Image/system/app/"
	apklistsize=${#apklist[@]}
	for (( i=0; i<${apklistsize}; i++ ))
	do
		f=${apklist[$i]}
		ApkLibExtract "$f"
		if [ ! -z "${APKLIBFILES}" ]
		then
			pushd "${APKLIBDIR}" 2>/dev/null
			DirToArray "*.so"
			s=${#FILEARRAY[@]}
			for (( j=0; j<${s}; j++ ))
			do
				so=${FILEARRAY[$i]}
				sudo rm "${WORKDIR}/Image/system/lib/$so" 2>>"${LOGFILE}"
			done
			popd 2>/dev/null
		fi
	done
	popd

	installApps_ExtractSystemLibs
	installApps_End
}

installApps_RemoveAllApk(){
	installApps_Begin

	pushd "${WORKDIR}/Image/system/app/"
	ls -1|grep -f "${PLUGINS}/installApps/apkblacklist.txt" > "$tempfile"
	FileToArray "$tempfile"

	installApps_RemoveListApk FILEARRAY[@]
}

installApps_RemoveSelectedApk(){
	installApps_Begin

	pushd "${WORKDIR}/Image/system/app/"
	ls -1|grep -f "${PLUGINS}/installApps/apkblacklist.txt" > "$tempfile"
	FileToArray "$tempfile"
	bl=("${FILEARRAY[@]}")
	ls -1|grep -v -f "${PLUGINS}/installApps/apkwhitelist.txt"|grep -v -f "${PLUGINS}/installApps/apkblacklist.txt" > "$tempfile"
	FileToArray "$tempfile"
	gl=("${FILEARRAY[@]}")

	ListCheckboxDlg bl[@] gl[@] "Remove system apps" "Choose apk files:"
	if [ $? -eq 0 ]
	then
		installApps_RemoveListApk FILEARRAY[@]
	fi
}

installApps_InstallListApk(){
	installApps_Begin
	apklist=("${!1}")
	apklistsize=${#apklist[@]}
	for (( i=0; i<${apklistsize}; i++ ))
	do
		f=${apklist[$i]}
		sudo cp $f "${WORKDIR}/Image/system/app/"  2>>"${LOGFILE}"
	done
	installApps_ExtractSystemLibs
	installApps_End
}

installApps_InstallAllAPK(){
	pushd "${PLUGINS}/installApps/apk"
	DirToArray "*apk"
	installApps_InstallListApk FILEARRAY[@]
	popd
}

installApps_InstallSelectedAPK(){
	pushd "${PLUGINS}/installApps/apk"
	DirToArray "*apk"
	ListCheckboxDlg FILEARRAY[@] "" "Install apps as system" "Choose apk files:"
	if [ $? -eq 0 ]
	then
		installApps_InstallListApk FILEARRAY[@]
	fi
	popd
}

installApps_Menu(){
	if [ "${WORKMODE}" != "In progress" ] && [ "${WORKMODE}" != "Image" ]
	then
		dialogOK "You should extract image files before continue..."
		return
	fi

	while [ true ]
	do
		dialogBT
		dialog --colors --backtitle "${DIALOGBT}" --title "Install system apps" --menu "Select:" 20 70 10 \
			"clean" "Remove system apps" \
			"busybox" "Install busybox" \
			"su" "Install su" \
			"apk" "Install apps as system" \
			"X" "Exit" 2> $tempfile
		case $? in
			0)
				s=`cat $tempfile`
				case $s in
					"busybox")
						installApps_BB
						;;
					"su")
						installApps_SU
						;;
					"clean")
						installApps_RemoveSelectedAPK
						;;
					"apk")
						installApps_InstallSelectedAPK
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

