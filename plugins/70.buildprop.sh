#!/bin/bash
set -vx

#MenuAdd "Modify build.prop" "buildprop_Menu"

#source 00.common.sh
#WORKDIR="../work/"
#GetBuildProp "ro.build.id"
#echo $BUILDPROP

#SetBuildProp "ro.build.id" "TeSt999"
#SetBuildProp "test.prop" "TeSt999"

buildPropFix(){
        pushd "${WORKDIR}/Image/system"
        property=$1
        value=$2
        fn=""
}

buildprop_Menu(){
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
						installApps_RemoveSelectedApk
						;;
					"apk")
						installApps_InstallSelectedApk
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

