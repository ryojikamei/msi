#!/bin/ash

rm -f ../stats/sysinfo
echo "SI_INFO_M=`uname -m`" >> ../stats/sysinfo
echo "SI_INFO_N=`uname -n`" >> ../stats/sysinfo
echo "SI_INFO_R=`uname -r`" >> ../stats/sysinfo
#SI_INFO_S=`uname -s`

