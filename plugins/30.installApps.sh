#!/bin/bash
#set -vx

MenuAdd "Install system apps" "installMenu"

installFixDirPermissions(){
	path=$1
	uid=$2
	gid=$3
	mod=$4
	find ${path} -type f -print0| xargs -0 sudo chmod ${mod} 2>>${LOGFILE}
	find ${path} -type f -print0| xargs -0 sudo chown ${uid} 2>>${LOGFILE}
	find ${path} -type f -print0| xargs -0 sudo chgrp ${gid} 2>>${LOGFILE}
}

installFixFilePermissions(){
	fn=$1
	uid=$2
	gid=$3
	mod=$4
	sudo chmod ${mod} "$fn" 2>>"${LOGFILE}"
	sudo chown ${uid} "$fn" 2>>"${LOGFILE}"
	sudo chgrp ${gid} "$fn" 2>>"${LOGFILE}"
}

installBegin(){
	pushd Image
	sudo mount system.img system -o loop 2>>"${LOGFILE}"
}

installEnd(){
	installFixDirPermissions system/bin/ 0 0 0755
	installFixDirPermissions system/xbin/ 0 0 0755
	sudo chmod +s system/xbin/su
	installFixDirPermissions system/app/ 0 0 0644
	sudo umount -f system 2>>"${LOGFILE}"
	popd
}

installBB(){
	installBegin

	sudo cp "${BASEDIR}/plugins/installApps/bin/busybox" system/xbin/busybox 2>>"${LOGFILE}"

	for c in `cat "${BASEDIR}/plugins/installApps/bin/busybox.lst"`
	do
		dst="system/xbin/${c}"
		if [ -f "$dst" ] || [ -L "$dst" ]
		then
			sudo mv "$dst" "${dst}#"
		fi

		sudo ln -s /system/xbin/busybox ${dst} 2>>"${LOGFILE}"
	done

	installEnd
}

installSU(){
	installBegin
	sudo mv system/bin/su "system/bin/su#" 2>/dev/null 
	sudo mv system/xbin/su "system/xbin/su#" 2>/dev/null

	sudo cp "${BASEDIR}/plugins/installApps/bin/su" system/xbin/su 2>>"${LOGFILE}"
	sudo cp "${BASEDIR}/plugins/installApps/bin/Superuser.apk" system/app/ 2>>"${LOGFILE}"

	installEnd
}

installAllAPK(){
	installBegin

	pushd ${BASEDIR}/plugins/installApps/apk

	for f in *apk
	do
		sudo cp "$f" "${WORKDIR}/Image/system/app/"  2>>"${LOGFILE}"
	done

	popd

	installEnd
}

installAPK(){
	installBegin

	pushd ${BASEDIR}/plugins/installApps/apk
	n=0
	for f in *apk
	do
		APK[$n]="\"$f\" \"\" off"
		n=$[n+1]
	done

	echo ${APK[@]}| xargs dialog --colors --backtitle "${DIALOGBT}" --title "Install apps as system" --checklist "Choose apk:" 20 70 15 2>$tempfile

	cat $tempfile| xargs sudo cp -t "${WORKDIR}/Image/system/app/"  2>>"${LOGFILE}"

	popd

	installEnd
}

installMenu(){
	if [ "${WORKMODE}" != "In progress" ] && [ "${WORKMODE}" != "Image" ]
	then
		dialogOK "You should extract image files before continue..."
		return
	fi

	while [ true ]
	do
		dialogBT
		dialog --colors --backtitle "${DIALOGBT}" --title "Install system apps" --menu "Select:" 20 70 10 \
			"busybox" "Install busybox" \
			"su" "Install su" \
			"apk" "Install apps as system" \
			"X" "Exit" 2> $tempfile
		case $? in
			0)
				s=`cat $tempfile`
				case $s in
					"busybox")
						installBB
						;;
					"su")
						installSU
						;;
					"apk")
						installAPK
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

