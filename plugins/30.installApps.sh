#!/bin/bash
#set -vx

MenuAdd "Install system apps" "installMenu"

installFixPermissions(){
	sudo chmod 0755 system/bin/*
	sudo chown 0 system/bin/*
	sudo chgrp 0 system/bin/*

	sudo chmod 0755 system/xbin/*
	sudo chown 0 system/xbin/*
	sudo chgrp 0 system/xbin/*

	sudo chmod 6755 system/xbin/su
	sudo chown 0 system/xbin/su
	sudo chgrp 0 system/xbin/su

	sudo chmod 0644 system/app/*
	sudo chown 0 system/app/*
	sudo chgrp 0 system/app/*
}

installBegin(){
	pushd ${WORKDIR}/Image
	sudo mount system.img system -o loop
}

installEnd(){
        installFixPermissions
	sudo umount -f system
	popd
}

installBB(){
	installBegin

	sudo cp ${BASEDIR}/plugins/installApps/bin/busybox system/xbin/busybox

	for c in `cat ${BASEDIR}/plugins/installApps/bin/busybox.lst`
	do
		sudo ln -s /system/xbin/busybox system/xbin/${c}
	done

	installEnd
}

installSU(){
	installBegin
	sudo mv system/bin/su system/bin/su.old 2>/dev/null
	sudo mv system/xbin/su system/xbin/su.oldd 2>/dev/null

	sudo cp ${BASEDIR}/plugins/installApps/bin/su system/xbin/su
	sudo cp ${BASEDIR}/plugins/installApps/bin/Superuser.apk system/app/

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

        cat $tempfile| xargs sudo cp -t ${WORKDIR}/Image/system/app/ 

        popd

	installEnd
}

installMenu(){

	if [ "${WORKMODE}" != "In progress" ]
	then
		dialogMSG "You should extract image files before continue..."
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
		esac
	done
}

