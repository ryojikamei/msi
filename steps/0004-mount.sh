#!/bin/ash

#CONFS
source ../confs/global
source ../confs/mount
SI_TITLE=" Set Mount Point "

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

#######################################

#initialize
rm -f ../stats/mount
for l in `$FDISK_L | grep Linux | tr -d '*' | tr -s ' ' | tr ' ' = `; do
	p=`echo $l | cut -f1 -d=`
	s=`echo $l | cut -f4 -d=`
	sm=`expr $s / 1024`
	sg=`expr $sm / 1024`
	st=`expr $sg / 1024`
	if [ $st -ge 10 ]; then
		TAG="${p},${st}TB"
	else if [ $sg -ge 10 ]; then
		TAG="${p},${sg}GB"
	else
		TAG="${p},${sm}MB"
	fi
	fi
	t=`echo $l | cut -f7 -d=`
	if [ "$t" == "swap" ]; then
		ITEM="swap"
	else
		ITEM="(none)"
	fi
	echo "${TAG}=${ITEM}" >> ../stats/mount
done

# Main Loop
MENU_H=`expr $SI_MAX_H - 8`
# code=3 is Rename
ret=3
while [ "$ret" -eq 3 ]; do

	# read
	PART_ITEMS=""
	for l in `cat ../stats/mount`; do
		TAG=`echo $l | cut -f1 -d=`
		ITEM=`echo $l | cut -f2 -d=`
		PART_ITEMS="$PART_ITEMS $TAG $ITEM"
	done

	# show
	msg="Select partitions and set mount points to install Linux. At least one root(/) partition and swap(swap) partitions are required to install. On some systems /boot partition is required to boot Linux properly."
	dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --inputmenu "$msg" $SI_MAX_H $SI_MAX_W $MENU_H $PART_ITEMS 2>../stats/mount-rename
	ret=$?

	# cancel
	if [ $ret -eq 1 ]; then
		exit 1
	fi

	mv ../stats/mount ../stats/mount-prev

	# apply the change
	_TAG=""
	if [ "x`grep ^RENAMED ../stats/mount-rename`" != "x" ]; then
		_TAG=`cat ../stats/mount-rename | cut -f2 -d' '`
		_ITEM=`cat ../stats/mount-rename | cut -f3 -d' '`
	fi
	for l in `cat ../stats/mount-prev`; do
		TAG=`echo $l | cut -f1 -d=`
		if [ "x$TAG" == "x$_TAG" ]; then
			ITEM=$_ITEM
		else
			ITEM=`echo $l | cut -f2 -d=`
		fi
		echo "${TAG}=${ITEM}" >> ../stats/mount
	done

	# validation with sanitize
	PART_ITEMS=""
	root=0
	swap=0
	error=0
	warning=0
	err_str=""
	warn_str=""
	for l in `cat ../stats/mount`; do
		TAG=`echo $l | cut -f1 -d=`
		ITEM=`echo $l | cut -f2 -d=`

		case "$ITEM" in
		'(none)')
			ITEM=""
			;;
		'swap')
			swap=1
			;;
		'/')	
			root=1
			;;
		'')
			ITEM=""
			;;
		*)
			ITEM="/`echo $ITEM | cut -c2- | tr -d [:punct:] | tr [:blank:] _`"
			if [ "`echo "$ITEM" | cut -c1`" != '/' ]; then
				error=1
				err_str="$ITEM:Any mount points should lead with '/'.\n"
			fi
		esac

		if [ "x$ITEM" == "x" ]; then
			ITEM="(none)"
		fi
		PART_ITEMS="${PART_ITEMS}\n - $TAG: $ITEM"
	done

	if [ $root -ne 1 ]; then
		error=1
		err_str="${err_str}Root(/) partition is not found.\n"
	fi
	if [ $swap -ne 1 ]; then
		warning=1
		warn_str="${warn_str}Swap partition is not found.\n"
	fi

	if [ $error -ne 0 ]; then
		title="Mount point errors"
		msg="There are problems at mount point configuration.\n${err_str}"
		dialog --backtitle "$SI_BACKTITLE" --title "$title" --msgbox "$msg" $SI_MAX_H $SI_MAX_W 
		ret=3
	fi
	if [ $warning -ne 0 ]; then
		title="Mount point warnings"
		msg="There are stranges at mount point configuration.\n ${err_str} Can we proceed?"
		dialog --backtitle "$SI_BACKTITLE" --title "$title" --yesno "$msg" $SI_MAX_H $SI_MAX_W 
		ret=$?
		if [ $ret -eq 0 ]; then
			ret=0
		else
			ret=3
		fi
	fi

	# final confirm.
	if [ $ret -eq 0 ]; then
		title="Confirm Mount point"
		msg="Mount points are set as follows:\n$PART_ITEMS"
		dialog --backtitle "$SI_BACKTITLE" --title "$title" --yesno "$msg" $SI_MAX_H $SI_MAX_W 
		ret=$?
		if [ $ret -eq 0 ]; then
			ret=0
		else
			ret=3
		fi
	fi
done

echo "DEBUG:"
cat ../stats/mount
printf "$err_str"
printf "$warn_str"
echo $ret

return $ret
