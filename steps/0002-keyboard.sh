#!/bin/ash

#CONFS
source ../confs/global
source ../confs/keyboard
source ../stat/personalize
SI_TITLE=" Choose Keyboard "

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
	KBD_DIR="$SI_KBD_DIR/i386"
else if [ $SI_INFO_M="x86_64" ]; then
	KBD_DIR="$SI_KBD_DIR/i386"
else
	echo "Unsupported machine architecture: $SI_INFO_M"
	exit 1
fi
fi

#######################################
msg="Which keyboard do you have?"
KBD_LIST=`tar -tf $KBD_DIR/kmaps.tar.gz`
for m in $KBD_LIST; do
	KBD_ITEMS="$KBD_ITEMS $m _"
done

MENU_H=`expr $SI_MAX_H - 8`
dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --menu "$msg" $SI_MAX_H $SI_MAX_W $MENU_H $KBD_ITEMS 2>../stats/kmap
if [ $? -ne 0 ]; then
	echo "Error choosing keyboard!"
	exit 1
fi
echo "" >>../stats/kmap
KMAP=`cat ../stats/kmap`

cd /tmp
tar xf $KBD_DIR/kmaps.tar.gz $KMAP
loadkmap < $KMAP
ret=$?

$D_CAT ../stats/kmap
$D_SLEEP
return $ret
