#!/bin/ash

#CONFS
source ../confs/global
source ../confs/mount
source ../stat/personalize  
SI_TITLE=" Configure Network Basics "

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

#if [ $SI_INFO_M="i386" ]; then
#	FDISK=/sbin/fdisk
#	FDISK_L="/sbin/fdisk -l"
#else if [ $SI_INFO_M="x86_64" ]; then
#	FDISK=/sbin/fdisk
#	FDISK_L="/sbin/fdisk -l"
#else
#	echo "Unsupported machine architecture: $SI_INFO_M"
#	exit 1
#fi
#fi

#######################################

#initialize
rm -f ../stats/net-basics
echo "Host_Name=noname" >> ../stats/net-basics
echo "Domain_Name=linux.name" >> ../stats/net-basics

# Main Loop
MENU_H=`expr $SI_MAX_H - 8`
# code=3 is Rename
ret=3
while [ "$ret" -eq 3 ]; do
	# auto configuration or not
	msg="Do we get basic network configuration from dhcp?"
	dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --yesno "$msg" 0 0
	ret=$?
	if [ $ret -eq 0 ]; then
		echo "Auto_Configuration=yes" > ../stats/net-basics
		ret=0
		continue
	fi

	# read
	NET_ITEMS=""
	for l in `cat ../stats/net-basics`; do
		TAG=`echo $l | cut -f1 -d=`
		ITEM=`echo $l | cut -f2 -d=`
		NET_ITEMS="$NET_ITEMS $TAG $ITEM"
	done

	# show
	msg="Set default hostname and domainname. Note that they are overwritten if the dhcpclient was gotten those information."
	dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --inputmenu "$msg" $SI_MAX_H $SI_MAX_W $MENU_H $NET_ITEMS 2>../stats/net-basics-rename
	ret=$?

	# cancel
	if [ $ret -eq 1 ]; then
		exit 1
	fi

	mv ../stats/net-basics ../stats/net-basics-prev

	# apply the change
	_TAG=""
	if [ "x`grep ^RENAMED ../stats/net-basics-rename`" != "x" ]; then
		# XXX: cut is heavily depend on tag name, 
		# so tag name should have same number of space(' ')s
		_TAG=`cat ../stats/net-basics-rename | cut -f2-3 -d' ' | tr ' ' _`
		_ITEM=`cat ../stats/net-basics-rename | cut -f4 -d' '`
	fi
	for l in `cat ../stats/net-basics-prev`; do
		TAG=`echo $l | cut -f1 -d=`
		if [ "x$TAG" == "x$_TAG" ]; then
			ITEM=$_ITEM
		else
			ITEM=`echo $l | cut -f2 -d=`
		fi
		echo "${TAG}=${ITEM}" >> ../stats/net-basics
	done

	# validation with sanitize
#	NET_ITEMS=""
	#root=0
	#swap=0
	#error=0
	#warning=0
	#err_str=""
	#warn_str=""
	#for l in `cat ../stats/mount`; do
	#	TAG=`echo $l | cut -f1 -d=`
	#	ITEM=`echo $l | cut -f2 -d=`
#
	#	case "$ITEM" in
		#'(none)')
			#ITEM=""
			#;;
		#'swap')
			#swap=1
			#;;
		#'/')	
			#root=1
			#;;
		#'')
			#ITEM=""
			#;;
		#*)
			#if [ "`echo "$ITEM" | cut -c1`" != '/' ]; then
				#error=1
				#err_str="$ITEM:Any mount points should lead with '/'.\n"
			#fi
			#ITEM="/`echo $ITEM | cut -c2- | tr -d [:punct:] | tr [:blank:] _`"
		#esac

		#if [ "x$ITEM" == "x" ]; then
			#ITEM="(none)"
		#fi
		#NET_ITEMS="${NET_ITEMS}\n - $TAG: $ITEM"
#	done

#	if [ $root -ne 1 ]; then
#		error=1
#		err_str="${err_str}Root(/) partition is not found.\n"
#	fi
#	if [ $swap -ne 1 ]; then
#		warning=1
#		warn_str="${warn_str}Swap partition is not found.\n"
#	fi
#
	if [ $error -ne 0 ]; then
		title="Network Configuration Errors"
		msg="There are problems at network configuration.\n${err_str}"
		dialog --backtitle "$SI_BACKTITLE" --title "$title" --msgbox "$msg" $SI_MAX_H $SI_MAX_W 
		ret=3
	fi
	if [ $warning -ne 0 ]; then
		title="Network Configuration Warnings"
		msg="There are stranges at network configuration.\n ${err_str} Can we proceed?"
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
		title="Confirm Network Basic Configuration"
		msg="Network basic configuration is set as follows:\n$NET_ITEMS"
		dialog --backtitle "$SI_BACKTITLE" --title "$title" --yesno "$msg" $SI_MAX_H $SI_MAX_W 
		ret=$?
		if [ $ret -eq 0 ]; then
			ret=0
		else
			ret=3
			continue
		fi
	fi
done

# auto bootup or not
msg="Do we set basic network configuration at bootup?"
dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --yesno "$msg" 0 0
ret=$?
if [ $ret -eq 0 ]; then
	echo "Auto_Bootup=yes" >> ../stats/net-basics
else
	echo "Auto_Bootup=no" >> ../stats/net-basics
fi

$D_ECHO "DEBUG:"
$D_CAT ../stats/net-basics
$D_PRINTF "$err_str"
$D_PRINTF "$warn_str"
$D_ECHO "return: $ret"
$D_SLEEP

return $ret
