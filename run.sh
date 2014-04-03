#!/bin/ash

if [ -f confs/global ]; then
	source confs/global
else
	source ../confs/global
fi

prev=0
curr=1
next=2
cd steps
while [ 1 ]; do

	name=`printf '%04d' ${curr}`
	shell=`ls ${name}-*` 2>/dev/null
	if [ "x$shell" == "x" ]; then
		exit 0
	else
		$D_ECHO "RUN: $shell"
		$D_SLEEP
		./$shell
	fi
	case "$?" in
	0)
		prev=$curr
		curr=$next
		next=`expr $next + 1`
		$D_ECHO "RUN: will forward to $curr"
		$D_SLEEP
		;;
	*)
		next=$curr
		curr=$prev
		prev=`expr $prev - 1`
		$D_ECHO "RUN: will back to $curr"
		$D_SLEEP
	esac

done
