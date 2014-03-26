#!/bin/ash

#CONFS
source ../confs/global
SI_TITLE=" $SI_DISTNAME "

#REQUIREMENTS
#PROGRAM
for r in dialog; do
	if [ "x`which $r`" == "x" ]; then
		echo "Essential executable $r is not found!"
		exit 1
	fi
done

#ARCH
if [ ! -f ../stats/sysinfo ]; then
../utils/sysinfo
fi
source ../stats/sysinfo

#######################################
dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --msgbox "Welcome to $SI_DISTNAME Installer" $SI_MAX_H $SI_MAX_W
#dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --textbox ../LICENSE $SI_MAX_H $SI_MAX_W
return $?
