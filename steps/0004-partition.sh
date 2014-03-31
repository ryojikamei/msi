#!/bin/ash

#CONFS
source ../confs/global
source ../confs/part
SI_TITLE=" Partition selection "

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
msg="Select partitions to install Linux. At least one root(/) partition and swap(swap) partitions are required to install. On some systems /boot partition is required to boot Linux properly."

#initialize
rm -f ../stats/part
for l in `$FDISK -l | grep Linux | tr -d '*' | tr -s ' ' | tr ' ' = `; do
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
	echo "${TAG}=${ITEM}" >> ../stats/part
done

# Main Loop
MENU_H=`expr $SI_MAX_H - 8`
# code=3 is Rename
ret=3
while [ "$ret" -eq 3 ]; do

	# read
	PART_ITEMS=""
	for l in `cat ../stats/part`; do
		TAG=`echo $l | cut -f1 -d=`
		ITEM=`echo $l | cut -f2 -d=`
		PART_ITEMS="$PART_ITEMS $TAG $ITEM"
	done

	# show
	dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --inputmenu "$msg" $SI_MAX_H $SI_MAX_W $MENU_H $PART_ITEMS 2>../stats/part-rename
	ret=$?
	mv ../stats/part ../stats/part-prev

	# apply the change
	_TAG=""
	if [ "x`grep ^RENAMED ../stats/part-rename`" != "x" ]; then
		_TAG=`cat ../stats/part-rename | cut -f2 -d' '`
		_ITEM=`cat ../stats/part-rename | cut -f3 -d' '`
	fi
	for l in `cat ../stats/part-prev`; do
		TAG=`echo $l | cut -f1 -d=`
		if [ "x$TAG" == "x$_TAG" ]; then
			ITEM=$_ITEM
		else
			ITEM=`echo $l | cut -f2 -d=`
		fi
		echo "${TAG}=${ITEM}" >> ../stats/part
	done

	# validation or sanitize
	PART_ITEMS=""
	root=0
	swap=0
	error=0
	warning=0
	for l in `cat ../stats/part`; do
		TAG=`echo $l | cut -f1 -d=`
		ITEM=`echo $l | cut -f2 -d=`

		if [ $ITEM == 'swap' ]; then
			swap=1
		else
			if [ $ITEM == '/' ]; then
				root=1
			fi
			if [ `echo $ITEM | cut -c1` != '/' ]; then
				error=1
				err_str="Any mount points should lead with '/'.\n"
			fi
		fi
		if [ $root -ne 1 ]; then
			error=1
			err_str="${err_str}Root(/) partition is not found.\n"
		fi
		if [ $swap -ne 1 ]; then
			warning=1
			warn_str="${err_str}Swap partition is not found.\n"
		fi

		PART_ITEMS="$PART_ITEMS $TAG $ITEM"
	done
	

done

echo "DEBUG:"
cat ../stats/part
echo $ret

return $ret
