#!/bin/ash

#CONFS
source ../confs/global
source ../confs/mkfs
SI_TITLE=" Format Filesystems "

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
	FDISK_L="/sbin/fdisk -l"
else if [ $SI_INFO_M="x86_64" ]; then
	FDISK=/sbin/fdisk
	FDISK_L="/sbin/fdisk -l"
else
	echo "Unsupported machine architecture: $SI_INFO_M"
	exit 1
fi
fi

if [ ! -f ../stats/mount ]; then
	echo "Mount configuration is required beforehand."
	exit 1
fi

#######################################
msg="Following partitions are going to be formatted into Linux filesystem. You can change filesystem type for each partition."
FS_ITEMS="Format_Partitons (All_data_are_wiped_immediately!)"
for m in `cat ../stats/mount | grep -v '=(none)'`; do
	devsize=`echo $m | cut -f1 -d'='`
	dev=`echo $devsize | cut -f1 -d','`
	size=`echo $devsize | cut -f2 -d','`
	mp=`echo $m | cut -f2 -d'='`
	if [ $mp == 'swap' ]; then
		fs="Swap"
	else
		fs="Ext3"
	fi
	FS_ITEMS="$FS_ITEMS :$fs:$dev $size"
done

MENU_H=`expr $SI_MAX_H - 8`
ret=0
while [ "$ret" -eq 0 ]; do 
	dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --menu "$msg" $SI_MAX_H $SI_MAX_W $MENU_H $FS_ITEMS 2>../stats/fs
	ret=$?
	$D_ECHO $ret
	$D_SLEEP
	if [ $ret -ne 0 ]; then
		echo "Cancel formatting filesystems."
		exit 1
	fi
	FS=`grep ^: ../stats/fs`
				echo "1"
	if [ "x$FS" == "x" ]; then
		ret=3
	else
		type=`echo $FS | cut -f2 -d:`
		dev=`echo $FS | cut -f3 -d:`
		if [ "$type" == "Swap" ]; then
			continue
		else
			for t in Ext2 Ext3 Ext4; do
				echo "2"
				if [ $t == $type ]; then
					flag=1
				else
					flag=0
				fi
				echo "3"
				$D_SLEEP
				RADIO_ITEMS='$RADIO_ITEMS $t "$t filesystem" $flag'
			done
		fi
		msg="What filesystem would you like to use for $dev?"
		dialog --radiolist "msg" 0 0 10 $RADIO_ITEMS
		cat ../stats/disk
		ret=0
	fi
done
if [ $ret -ne 1 ]; then
	ret=0
fi

$D_ECHO -n "mkfs:"
$D_ECHO $ret
$D_SLEEP
return $ret
