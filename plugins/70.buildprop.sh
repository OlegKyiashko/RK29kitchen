#!/bin/bash
set -vx

MenuAdd "Modify build.prop" "buildprop_Menu"

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
			"tz" "Change default TimeZone" \
			"lc" "Change default locale" \
			"wifi" "Change default wifi settings" \
			"X" "Exit" 2> $tempfile
		case $? in
			0)
				s=`cat $tempfile`
				case $s in
					"tz")
						buildprop_TZ
						;;
					"lc")
						buildprop_LC
						;;
					"wifi")
						buildprop_wifi
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

