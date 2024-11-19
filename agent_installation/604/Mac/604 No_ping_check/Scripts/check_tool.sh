#!/bin/bash

SCRIPT_MODULE="check_tool"
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

# func of check tool
need_tool=()
cnt=0
function check_tool(){
    for i in $*;
	do
        which $i > /dev/null
        if [ $? -ne 0 ]; then
	        need_tool[cnt]="$i"
		    cnt=`expr $cnt + 1`
	    fi
	done
}

#Check all dependent tools before installation and ask users to install the uninstalled tools and if you need to add the tools please add it here.
#This logic needs to remain before the script execution, or else there is no check on dependent tools.
check_tool grep sed awk df openssl crontab tar

len=${#need_tool[@]}

if [ $len -ne 0 ];then
    # echo "Installer asks tools bellow:" # echo "Installer asks tools as following:" 
	echo -e "\033[31m Installer asks tools bellow:\033[0m"
	for v in ${need_tool[@]};
	do
	    # echo "$v"
		echo -e "\033[31m $v \033[0m"
		write_log "error" "need to install tool: $v"
	done

	if [ $len -le 1 ];then
	    # echo "please install it"
		# echo -e "\033[31m please install it \033[0m"
		echo -e "\033[31m please install it \033[0m"
	else
		# echo "please install them"
		# echo -e "\033[31m please install them \033[0m"
		echo -e "\033[31m please install them \033[0m"
	fi
	exit 1
fi

write_log "info" "check tool success"
exit 0
