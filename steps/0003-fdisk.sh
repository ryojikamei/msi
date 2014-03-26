#!/bin/ash

#CONFS
source ../confs/global
source ../confs/fdisk
SI_TITLE=" Partition table manipulation "

#REQUIREMENTS
#PROGRAM
#for r in dialog /usr/bin/find; do
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
msg="Preparing Linux partition and Linux swap partition are required to install Linux. Which keyboard do you have?"
#KBD_LIST=`/usr/bin/find $KBD_DIR -path $KBD_DIR/include -prune -type f -o -name *map*`
KBD_LIST=`find $KBD_DIR -type f -name "*map*" | cut -f6- -d'/' | grep -v ^include | sort`
for m in $KBD_LIST; do
	KBD_ITEMS="$KBD_ITEMS $m"
	KBD_ITEMS="$KBD_ITEMS `basename $m .map.gz | tr [:lower:] [:upper:]`"
	#KBD_ITEMS="$KBD_ITEMS `basename $m .map.gz | awk '{print toupper(substr($1,1,1))substr($1,2)}'`"
done

MENU_H=`expr $SI_MAX_H - 8`
dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --menu "$msg" $SI_MAX_H $SI_MAX_W $MENU_H $KBD_ITEMS 2>../stats/kmap
if [ $? -ne 0 ]; then
	echo "Error choosing keyboard!"
	exit 1
fi
echo "" >>../stats/kmap
KMAP=$KBD_DIR/`cat ../stats/kmap`
clear
loadkeys $KMAP
return $?