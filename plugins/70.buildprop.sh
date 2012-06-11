#!/bin/bash
#set -vx

MenuAdd "Modify build.prop" "buildprop_Menu"

buildprop_TZ(){
	GetBuildProp "persist.sys.timezone"
	ListMenuDlg "${PLUGINS}/buildprop/timezone" "Change default timezone" "Current:${BUILDPROP}\nSelect:"
	case $? in
		0)
			tz=`cat $tempfile`
			SetBuildProp "persist.sys.timezone" "$tz"
			;;
	esac
}

buildprop_LC(){
	lngpn="ro.product.locale.language"
	rgnpn="ro.product.locale.region"
	GetBuildProp "$lngpn"
	lng=$BUILDPROP
	GetBuildProp "$rgnpn"
	rgn=$BUILDPROP
	FileMenuMenuDlg "${PLUGINS}/buildprop/locale" "Change default locale" "Current: ${lng}_${rgn}\nSelect:"
	case $? in
		0)
			r=`cat $tempfile`
			lng=${r:0:2}
			rgn=${r:3:2}
			SetBuildProp "$lngpn" "$lng"
			SetBuildProp "$rgnpn" "$rgn"
			;;
	esac
}

buildprop_DateFormat(){
	pn="ro.com.android.dateformat"
	GetBuildProp "$pn"
	ListMenuDlg "${PLUGINS}/buildprop/dateformat" "Change default dateformat" "Current:${BUILDPROP}\nSelect:"
	case $? in
		0)
			tz=`cat $tempfile`
			SetBuildProp "$pn" "$tz"
			;;
	esac
}

buildprop_WIFI(){
	pn="wifi.supplicant_scan_interval"
	GetBuildProp "$pn"
	ListMenuDlg "${PLUGINS}/buildprop/wifiScanInterval" "Change default wifi scan interval" "Current:${BUILDPROP}\nSelect:"
	case $? in
		0)
			v=`cat $tempfile`
			SetBuildProp "$pn" "$v"
			;;
	esac
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
		dialog --colors --backtitle "${DIALOGBT}" --title "Modify build.prop" --menu "Select:" 20 70 10 \
			"tz" "Change default timezone" \
			"lc" "Change default locale" \
			"dateformat" "Change default dateformat" \
			"wifi" "Change default wifi scan interval" \
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
					"dateformat")
						buildprop_DateFormat
						;;
					"wifi")
						buildprop_WIFI
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

