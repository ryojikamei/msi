#!/bin/ash

#CONFS
source ../confs/global
source ../confs/net
SI_TITLE=" Configure Network "

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

#######################################
# initialize
rm -f ../stats/net
for i in `ifconfig -a | grep 'Link encap' | tr -s ' '; do
	if=`echo $i | cut -f1 -d' '
	le=`echo $i | cut -f2- -d: | tr ' ' _
	echo "Auto,$if=$le" >> ../stats/net
fi


MENU_H=`expr $SI_MAX_H - 8`
ret=0
while [ "$ret" -eq 0 ]; do 
	# read
	NET_ITEMS="Continue Done_this_configuration_and_go_next"
	RADIO_ITEMS=""
	for l in `cat ../stats/net`; do
		NET_ITEMS="$NET_ITEMS `echo $l | tr = ' '`"
	done
	$D_ECHO $NET_ITEMS
	$D_SLEEP

	# show
	msg="Network configuration xxx"
	dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --menu "$msg" $SI_MAX_H $SI_MAX_W $MENU_H $NET_ITEMS 2>../stats/if
	ret=$?
	$D_ECHO $ret
	if [ $ret -ne 0 ]; then
		echo "Cancel configure netoworking."
		exit 1
	fi
	$D_SLEEP
	NIC=`grep , ../stats/if`
	if [ "x$NIC == "x" ]; then
		ret=3
	else
		tgt_type=`echo $NIC | cut -f1 -d,`
		tgt_dev=`echo $NIC | cut -f2 -d,`
		case "$tgt_dev" in
		eth*)
			continue
			;;
		*)
			continue
		esac


		exit

		if [ "$tgt_dev" == "Auto" ]; then
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
