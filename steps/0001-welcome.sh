#!/bin/ash

#CONFS
source ../confs/global
#SI_TITLE=" $SI_DISTNAME "

#REQUIREMENTS
#PROGRAM
for r in dialog; do
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

#initialize
rm -f ../stats/personalize
echo "SI_DISTNAME=NoName_Linux" >> ../stats/personalize
echo "SI_USERNAME=noname" >> ../stats/personalize
echo "SI_HOSTNAME=noname" >> ../stats/personalize
echo "SI_DOMAINNAME=linux.name" >> ../stats/personalize
echo "SI_BACKTITLE=\${SI_DISTNAME}_Installer" >> ../stats/personalize

# Main Loop                                                             
MENU_H=`expr $SI_MAX_H - 8`                                             
# code=3 is Rename                                                      
ret=3
while [ "$ret" -eq 3 ]; do

	# read
	PERSONAL_ITEMS=""
	for l in `cat ../stats/personalize`; do
		case `echo $l | cut -f1 -d=` in
		"SI_DISTNAME")
			TAG="System_Name"
			ITEM="`echo $l | cut -f2- -d=`"
			;;
		"SI_USERNAME")
			TAG="User_Name"
			ITEM="`echo $l | cut -f2 -d=`"
			;;
		"SI_HOSTNAME")
			TAG="Host_Name"
			ITEM="`echo $l | cut -f2 -d=`"
			;;
		"SI_DOMAINNAME")
			TAG="Domain_Name"
			ITEM="`echo $l | cut -f2 -d=`"
			;;
		*)
			TAG=""
			ITEM=""
		esac
		PERSONAL_ITEMS="$PERSONAL_ITEMS $TAG $ITEM"
	done

	# show
	msg="Welcome to $SI_DISTNAME Installer! Let's personalize $SI_USERNAME system."
	SI_TITLE=" $SI_DISTNAME "
	# XXX Very long domain name cannot be set
	dialog --backtitle "$SI_BACKTITLE" --max-input $SI_MAX_I --title "$SI_TITLE" --inputmenu "$msg" $SI_MAX_H $SI_MAX_W $MENU_H $PERSONAL_ITEMS 2>../stats/personalize-rename
	ret=$?

	# cancel
	if [ $ret -eq 1 ]; then
		exit 1
	fi

	mv ../stats/personalize ../stats/personalize-prev

	# apply the change
	_TAG=""
	if [ "x`grep ^RENAMED ../stats/personalize-rename`" != "x" ]; then
		_ITEM=`cat ../stats/personalize-rename | cut -f4- -d' '`
		case `cat ../stats/personalize-rename | cut -f2-3 -d' '` in
		"System Name")
			_TAG="SI_DISTNAME"
			if [ "x$_ITEM" == "x" ]; then
				_TAG="NoName_Linux"
			fi
			;;
		"User Name")
			_TAG="SI_USERNAME"
			if [ "x$_ITEM" == "x" ]; then
				_TAG="noname"
			fi
			;;
		"Host Name")
			_TAG="SI_HOSTNAME"
			if [ "x$_ITEM" == "x" ]; then
				_TAG="noname"
			fi
			;;
		"Domain Name")
			_TAG="SI_DOMAINNAME"
			if [ "x$_ITEM" == "x" ]; then
				_TAG="linux.name"
			fi
			;;
		esac
	fi
	for l in `cat ../stats/personalize-prev`; do
		TAG=`echo $l | cut -f1 -d=`
		if [ "x$TAG" == "x$_TAG" ]; then
			ITEM=`echo $_ITEM | tr ' ' _`
		else
			ITEM=`echo $l | cut -f2- -d=`
		fi
		echo "${TAG}=${ITEM}" >> ../stats/personalize
	done

	# re-read
	source ../stats/personalize

done
