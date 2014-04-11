#!/bin/ash

#CONFS
source ../confs/global
source ../confs/net
source ../stat/personalize  
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
echo "Continue=Done_this_configuration_and_go_next" > ../stats/net
echo "Basic_Configuration=Configure:Auto,Enable:Auto" >> ../stats/net
echo "IPv4_Configuration=Configure:Auto,Enable:Auto" >> ../stats/net
echo "IPv6_Configuration=Configure:Auto,Enable:No" >> ../stats/net

MENU_H=`expr $SI_MAX_H - 8`
ret=0
while [ $ret -eq 0 ]; do
	# read
	NET_ITEMS=""
	for l in `cat ../stats/net`; do
		NET_ITEMS="$NET_ITEMS `echo $l | tr = ' '`"
	done
	$D_ECHO $NET_ITEMS
	$D_SLEEP

	# show
	msg="Network configuration is required if you use networking. Pick a selection to change the settings. NOTE: Currently only eth0 is supported."
	dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --menu "$msg" $SI_MAX_H $SI_MAX_W $MENU_H $NET_ITEMS 2>../stats/netconf
	ret=$?
	$D_ECHO $ret
	if [ $ret -ne 0 ]; then
		echo "Cancel configure networking."
		#exit 1
		continue
	fi
	$D_SLEEP

	NEXT=`cat ../stats/netconf`
	case $NEXT in
	"Basic Configuration")
		./*-network-basics.sh
		;;
	"IPv4 Configuration")
		./*-network-ipv4.sh
		;;
	"IPv6 Configuration")
		./*-network-ipv6.sh
		;;
	*)
		ret=3
	esac

done
if [ $ret -ne 1 ]; then
	ret=0
fi

$D_ECHO -n "net:"
$D_ECHO $ret
$D_CAT ../stats/net
$D_ECHO -n "last selection:"
$D_CAT ../stats/netconf
$D_ECHO ""
$D_SLEEP
return $ret
