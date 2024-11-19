#!/bin/bash

SCRIPT_MODULE="check_digits"
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

# check system digits
uname -a | grep "64" > /dev/null
if [ $? -ne 0 ] ; then
	echo "edr agent only supports installation on 64 machines"
	write_log "error" "edr agent only supports installation on 64 machines"
	exit 1
else
	echo "edr agent is installing on 64 machines"
	write_log "info" "edr agent is installing on 64 machines"
fi
exit 0
