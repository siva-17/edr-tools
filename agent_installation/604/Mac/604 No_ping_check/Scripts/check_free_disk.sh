#!/bin/bash

SCRIPT_MODULE="check_free_disk"
g_szLogDir="/tmp"
g_szLogFileName="install_pre_check_log"
g_szLogFile="$g_szLogDir/$g_szLogFileName"

function write_log()
{
	local dateTime
	dateTime=$(date "+%Y/%m/%d %H:%M:%S")
	g_szLogFile="$g_szLogDir/$g_szLogFileName"

	if [ ! -d ${g_szLogDir} ]; then
		if mkdir -p "${g_szLogDir}" > /dev/null 2>&1; then
			echo "[$1][$dateTime][${SCRIPT_MODULE}]create dir ${g_szLogDir} successfully" >> "${g_szLogFile}" 2>&1
		else
			g_szLogFile="$g_szLogFileName"
			echo "[$1][$dateTime][${SCRIPT_MODULE}]create dir ${g_szLogDir} failed" >> "${g_szLogFile}" 2>&1
		fi
	fi

	echo "[$1][$dateTime][${SCRIPT_MODULE}]${2}" >> "${g_szLogFile}" 2>&1
}

#Check whether the free disk space of root directory is 1 GB (1024*1024=1048576) at least before installation
disk_must=`expr 1024 \* 1024`
avail_disk=`df -H "."  | awk 'NR==2{print $4}'`
str_unit="G"
result=$(echo $avail_disk | grep "${str_unit}")
if [[ "$result" != "" ]]
then
    avail_disk=${avail_disk/G/}
    avail_disk=`expr $avail_disk \* 1048576`
else
    avail_disk=${avail_disk/M/}
    avail_disk=`expr $avail_disk \* 1024`
fi

if [ $avail_disk -lt $disk_must ]; then
    echo "space of startup disk is less than 1G,installed failed."
	write_log "error" "space of startup disk is less than 1G,installed failed."
	exit 1
fi

echo "info" "check free disk success"
write_log "info" "check free disk success"
exit 0
