#!/bin/ash

#CONFS
source ../confs/global
source ../confs/fdisk
SI_TITLE=" Partition table manipulation "

#REQUIREMENTS
#PROGRAM
for r in dialog find; do
	if [ "x`which $r`" == "x" ]; then
		echo "Essential executable $r is not found!"
		exit 1
	fi
done

#ARCH
if [ ! -f ../stats/sysinfo ]; then
../utils/sysinfo.sh
fi
source ../stats/sysinfo

if [ $SI_INFO_M="i386" ]; then
	FDISK=/sbin/fdisk
else if [ $SI_INFO_M="x86_64" ]; then
	FDISK=/sbin/fdisk
else
	echo "Unsupported machine architecture: $SI_INFO_M"
	exit 1
fi
fi

#######################################
msg="Preparing Linux partition and Linux swap partition are required to install Linux. Which disk do you want to manipulate by fdisk?"
DISK_ITEMS="Done Everything"
for l in `$FDISK -l | grep ^"Disk /dev" | tr -d ' '`; do
	s="/"`echo $l | cut -f1 -d: | cut -f2- -d/`
	d=`echo $l | cut -f2 -d:`
	DISK_ITEMS="$DISK_ITEMS $s $d"
done

MENU_H=`expr $SI_MAX_H - 8`
ret=0
while [ "$ret" -eq 0 ]; do 
	dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --menu "$msg" $SI_MAX_H $SI_MAX_W $MENU_H $DISK_ITEMS 2>../stats/disk
	ret=$?
	if [ $? -ne 0 ]; then
		echo "Error choosing hard disk!"
		exit 1
	fi
	DISK=`grep ^/dev ../stats/disk`
	if [ "x$DISK" == "x" ]; then
		ret=2
	else
		clear
		$FDISK `cat ../stats/disk`
	fi
done

return $ret
