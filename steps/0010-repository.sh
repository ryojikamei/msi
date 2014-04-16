#!/bin/ash

#CONFS
source ../confs/global
source ../confs/repo
source ../stats/personalize  
SI_TITLE=" Select Software Repository "

#REQUIREMENTS
#PROGRAM
for r in dialog find; do
	if [ "x`which $r`" == "x" ]; then
		echo "Essential Executable $r is not found!"
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
rm -f ../stats/repourl
echo "DEFAULT_URL=$DEFAULT_REPOSITORY_PATH/$SI_INFO_M" >> ../stats/repourl

ret=1
while [ "$ret" -eq 1 ]; do
	# Is default ok?
	if [ -d $DEFAULT_URL ]; then
		msg="This media contains software repository. We will use that if you choose \"Yes\"."
		dialog --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --yesno "$msg" 0 0
		ret=$?
		if [ $ret -eq 0 ]; then
			continue
		fi
	fi

	msg="Please input the URL to the Software directory.\n"
	msg="$msg  Samples:\n"
	msg="$msg    Local: cdrom://Software\n"
	msg="$msg    FTP: ftp://ftp.example.org/pub/NNL/1.0/Software\n"
	msg="$msg    HTTP: http://www.example.org/NNL/1.0/Software"
	dialog --max-input $SI_MAX_L --backtitle "$SI_BACKTITLE" --title "$SI_TITLE" --inputbox "$msg" $SI_MAX_H $SI_MAX_W 2> ../stats/repourl
	ret=$?

	#Validation
	error=0
	err_msg=""
	url=`grep "/Software$" ../stats/repourl`
	if [ "x$url" == "x" ]; then
		error=1
		err_msg="${err_msg} - The URL must be end with /Software.\n"
	fi

	method=`cat ../stats/repourl | cut -f1 -d:`
	case "$method" in
	'cdrom')
		if [ $error -eq 0 ]; then
			mkdir -p /tmp/cdrom
			mount /dev/cdrom /tmp/cdrom
			ret=$?
			if [ $ret -ne 0 ]; then
				error=1
				err_msg="${err_msg} - Error in mounting cdrom."
			else
				path="`echo $url | cut -c9-`/$SI_INFO_M"
				if [ ! -d $path ]; then
					error=1
					err_msg="${err_msg} - -This cdrom does not contain the repository."
				fi
			fi
			umount /tmp/cdrom 
			rmdir /tmp/cdrom
		fi
		;;
	'ftp')
		if [ $error -eq 0 ]; then
			wget $WGET_CHECK_OPT --spider $url$SI_INFO_M
			ret=$?
			if [ $ret -ne 0 ]; then
				error=1
				err_msg="${err_msg} - The URL is invalid or the network connection is unstable."
			fi
		fi
		;;
	'http')
		if [ $error -eq 0 ]; then
			wget $WGET_CHECK_OPT --spider $url$SI_INFO_M
			ret=$?
			if [ $ret -ne 0 ]; then
				error=1
				err_msg="${err_msg} - The URL is invalid or the network connection is unstable."
			fi
		fi
		;;
	*)
		error=1
		err_msg="${err_msg} - Only cdrom,ftp,http protocols are supported.\n"
	esac

	if [ $error -ne 0 ]; then
		title=" Repository Configuration Errors "
		msg="There are problems at repository configuration.\n${err_msg}"
		dialog --backtitle "$SI_BACKTITLE" --title "$title" --msgbox "$msg" $SI_MAX_H $SI_MAX_W
		ret=$error
	fi

done

$D_ECHO "DEBUG:"
$D_CAT ../stats/repourl
$D_PRINTF "$err_str"
$D_ECHO "return: $ret"
$D_SLEEP

return $ret
