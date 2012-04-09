#!/bin/bash
#set -vx

MenuAdd "Install system apps" "installMenu"

installBegin(){
	pushd ${WORKDIR}/Image
	sudo mount system.img system -o loop
}

installEnd(){
	sudo umount -f system
	popd
}

installBB(){
	installBegin

	cp ${BASEDIR}/plugins/installApps/bin/busybox system/xbin/busybox
	sudo chmod 0755 system/xbin/busybox
	sudo chown 0 system/xbin/busybox
	sudo chgrp 0 system/xbin/busybox

	for c in `cat ${BASEDIR}/plugins/installApps/bin/busybox.lst`
	do
		ln -s /system/xbin/busybox system/xbin/${c}
	done

	installEnd
}

installSU(){
	installBegin
	mv system/bin/su system/bin/su.old 2>/dev/null
	mv system/xbin/su system/xbin/su.oldd 2>/dev/null

	cp ${BASEDIR}/plugins/installApps/bin/su system/xbin/su
	sudo chmod 6755 system/xbin/su
	sudo chown 0 system/xbin/su
	sudo chgrp 0 system/xbin/su

	cp ${BASEDIR}/plugins/installApps/bin/Superuser.apk system/app/
	sudo chmod 0644 system/app/Superuser.apk
	sudo chown 0 system/app/Superuser.apk
	sudo chgrp 0 system/app/Superuser.apk

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

	echo ${APK[@]}| xargs dialog --title "Install apps as system" --checklist "Choose apk:" 20 70 15 2>$tempfile

	popd

	installEnd
}
installMenu(){

	if [ ${WORKMODE} != "In progress" ]
	then
		dialogMSG "You should extract image files before continue..."
		return
	fi

	while [ true ]
	do
		dialog --title "Install system apps" --menu "Select:" 20 70 10 \
			"busybox" "Install busybox" \
			"su" "Install su" \
			"apk" "Install apps as system"
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
					'X')
						return
						;;
				esac
				;;
			*)
				break
				;;
		esac
	done
}

