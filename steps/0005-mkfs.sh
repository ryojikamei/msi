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
#FS_ITEMS="Format_Partitons (All_data_are_wiped_immediately!)"
# initialize
rm -f ../stats/part
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
	echo "$fs,$dev=$size" >> ../stats/part
done

MENU_H=`expr $SI_MAX_H - 8`
ret=0
while [ "$ret" -eq 0 ]; do 
	# read
	FS_ITEMS="Format_Partitons (All_data_are_wiped_immediately!)"
	RADIO_ITEMS=""
	for l in `cat ../stats/part`; do
		FS_ITEMS="$FS_ITEMS `echo $l | tr = ' '`"
	done
	$D_ECHO $FS_ITEMS
	$D_SLEEP

	# show
	msg="Following partitions are going to be formatted into Linux filesystem. You can change filesystem type for each partition."
	dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --menu "$msg" $SI_MAX_H $SI_MAX_W $MENU_H $FS_ITEMS 2>../stats/fs
	ret=$?
	$D_ECHO $ret
	if [ $ret -ne 0 ]; then
		echo "Cancel formatting filesystems."
		exit 1
	fi
	$D_SLEEP
	FS=`grep , ../stats/fs`
	if [ "x$FS" == "x" ]; then
		ret=3
	else
		tgt_type=`echo $FS | cut -f1 -d,`
		tgt_dev=`echo $FS | cut -f2 -d,`
		if [ "$tgt_type" == "Swap" ]; then
			continue
		else
			FS_TYPES="Ext2 Ext3 Ext4 Keep_Current"
			FS_TYPES_H=4
			for type in $FS_TYPES; do
				if [ $type == $tgt_type ]; then
					flag="on"
				else
					flag="off"
				fi
				RADIO_ITEMS="$RADIO_ITEMS $type "${type}_Filesystem" $flag"
				$D_ECHO $RADIO_ITEMS
				$D_SLEEP
			done
		fi
		msg="What filesystem would you like to use for $tgt_dev?"
		dialog  --backtitle "$SI_BACKTITLE" --title " Choose Filesystem " --radiolist "$msg" 0 0 $FS_TYPES_H $RADIO_ITEMS 2>../stats/fs-change
		if [ $? -eq 1 ]; then
			continue
		fi
		#if [ "x`cat ../stats/fs-change`" == "x" ]; then
		#	continue
		#fi

		# apply the change
		mv ../stats/part ../stats/part-prev
		for l in `cat ../stats/part-prev`; do
			fsdev=`echo $l | cut -f1 -d=`
			size=`echo $l | cut -f2 -d=`
			fs=`echo $fsdev | cut -f1 -d,`
			dev=`echo $fsdev | cut -f2 -d,`
			if [ $dev == $tgt_dev ]; then
				fs=`cat ../stats/fs-change`
			fi
			echo "$fs,$dev=$size" >> ../stats/part
		done
			
	fi

done
if [ $ret -ne 1 ]; then
	ret=0
fi

$D_ECHO -n "mkfs:"
$D_ECHO $ret
$D_SLEEP
return $ret
