#!/bin/bash
SCRIPT_PATH=`cd $(dirname $0);pwd -P`
# echo "SCRIPT_PATH: ${SCRIPT_PATH}"

# !!! Note: !!!
# Edit and Comment in English, please

# set the runtime-system in English
export LANG=""
export LANGUAGE=""

# under HCI proxy, the mgr's ip address and download port
G2HPorxyIP=127.0.0.1
G2HProxyPort=18524
G2HProxyName=G2HProxy
NET_TOOL=netstat

# error code definition
ERR_NET_CONNECT=1002
ERR_MEMORY_SHORTAGE=1004
ERR_ALREADY_INSTALL=1010
ERR_ROOT_PRIVILIGE=1011
ERR_INVALID_PARAM=1012
ERR_COMMAND_MISS=1013
ERR_INSTALL_POSITION=1014
ERR_INSTALL_PATH=1015
ERR_CRON_SERVICE=1016
ERR_G2H_PORT_OCCUPIED=1017
ERR_UNSUPPORT_SYSTEM=1018

# system support list
WHITELIST=("CentOS 5 x86" "CentOS 5 x64" "CentOS 6 x86" "CentOS 6 x64" "CentOS 7 x64" 
            "Ubuntu 10 x86" "Ubuntu 10 x64" "Ubuntu 11 x86" "Ubuntu 11 x64" "Ubuntu 12 x86" 
            "Ubuntu 12 x64" "Ubuntu 13 x86" "Ubuntu 13 x64" "Ubuntu 14 x86" "Ubuntu 14 x64" 
            "Ubuntu 16 x86" "Ubuntu 16 x64" "Ubuntu 17 x86" "Ubuntu 17 x64" "Ubuntu 18 x86" 
            "Ubuntu 18 x64" "Ubuntu 20 x86" "Ubuntu 20 x64" 
            "Debian 6 x86" "Debian 6 x64" "Debian 7 x86" "Debian 7 x64" "Debian 8 x86" 
            "Debian 8 x64" "Debian 9 x86" "Debian 9 x64" 
            "RHEL 5 x86" "RHEL 5 x64" "RHEL 6 x86" "RHEL 6 x64" "RHEL 7 x64" 
            "SUSE 11" "SUSE 12" "SUSE 15" 
            "Oracle 5 x86" "Oracle 5 x64" "Oracle 6 x86" "Oracle 6 x64" "Oracle 7 x64" "AlmaLinux x64"
)

OS_NAME=
OS_VERSION=
OS_ARCHITECTURE=
OS_PLATFORMID=
OS_PLATFORM=

# get os name
obtainOpSystem(){
    OS_NAME="$(cat /etc/issue |grep -iEo "CentOS|Ubuntu|Debian|Red|SUSE|Oracle|AlmaLinux"|tr a-z A-Z)"
    if [[ -z "$OS_NAME" ]]; then
        if [[ -f "/etc/os-release" ]]; then
            OS_NAME="$(cat /etc/os-release|grep -E "^(ID)="|grep -iEo "CentOS|Ubuntu|Debian|Red|SUSE|Oracle|AlmaLinux"|tr a-z A-Z)"
        fi
        if [[ -z "$OS_NAME" && -f "/etc/redhat-release" ]]; then
            OS_NAME=$(cat /etc/redhat-release|grep -iEo "CentOS|Ubuntu|Debian|Red|SUSE|Oracle|AlmaLinux"|tr a-z A-Z)
        fi
    fi
    case $OS_NAME in
    "CENTOS")
        OS_NAME=CentOS;;
    "UBUNTU")
        OS_NAME=Ubuntu;;
    "DEBIAN")
        OS_NAME=Debian;;
    "RED")
        OS_NAME=RHEL;;
    "SUSE")
        OS_NAME=SUSE;;
    "ORACLE")
        OS_NAME=Oracle;;
    "ALMALINUX")
        OS_NAME=AlmaLinux;;
    esac
}

# get os-release version
obtainOpSystemVersion(){
    lsb_release -r &>/dev/null
    if [[ $? -eq 0 ]]; then
		# using 'lsb_release -r' firstly
        OS_VERSION=$(lsb_release -r|awk -F ":" '{print int($2)}')
    elif [[ -f "/etc/os-release" ]]; then
        OS_VERSION=$(grep -E "^(VERSION_ID)=" </etc/os-release|awk -F "=" '{print $NF}'|awk -F "." '{print $1}'|tr -cd "[0-9]")
    fi
    if [[ -z "$OS_VERSION" && -f "/etc/redhat-release" ]]; then
        OS_VERSION=$(cat /etc/redhat-release|tr -cd [0-9.]|awk -F "." '{print $1}')
    fi
}

# get os runtime bit
obtainSystemBit(){
    OS_ARCHITECTURE=$(getconf LONG_BIT)
    case $OS_ARCHITECTURE in 
    64)
        OS_ARCHITECTURE=x64;;
    32)
        OS_ARCHITECTURE=x86;;
    esac
}

# check if the OS is in 'system support list'
isInWhilteList(){
    if [[ "$OS_NAME" == "SUSE" ]]; then
        currSystem="$OS_NAME $OS_VERSION"
    else
        currSystem="$OS_NAME $OS_VERSION $OS_ARCHITECTURE"
    fi
    for(( i=0; i<${#WHITELIST[@]}; i++))
    do
        if [[ "$currSystem" == "${WHITELIST[i]}" ]]; then
            return 0
        fi        
    done
    echo "Warning:Current system:$currSystem, Not support,${WHITELIST[@]}"
    return 1
}

# main OS check precess
checkOpSystem(){
    obtainOpSystem
    if [[ -z "$OS_NAME" ]]; then
        echo "Failed to obtain operating system!"
        return 1
    fi
    obtainOpSystemVersion
    if [[ -z "$OS_VERSION" ]]; then
        echo "Failed to obtain the operating system version!"
        return 1
    fi
    obtainSystemBit
    if [[ -z "$OS_ARCHITECTURE" ]]; then
        echo "Failed to obtain system hardware architecture!"
        return 1
    fi
    isInWhilteList
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    return 0
}

# can't not be installed in domestic OS.
# if returnVal == 1, should stop installing now.
checkIsGchOpSystem() {
    OS_PLATFORMID=`cat /etc/os-release | sed 's/^[ \t]*//g' | grep ^ID= | sed 's/ID=\([0-9a-zA-Z-]*\)/\1/g' | awk '{print tolower($1)}'`
    OS_PLATFORM=$(uname -m)
    OS_SYSBIT=$(getconf LONG_BIT)
    
    if [ "${OS_SYSBIT}" != "64" ]; then
		return 1
    fi

    if [[ "${OS_PLATFORM}" != *"x86_64"* ]] && [[ "${OS_PLATFORM}" != *"i386"* ]] && [[ "${OS_PLATFORM}" != *"i686"* ]]; then
        echo "This operate system id is ${OS_PLATFORMID}, bit is ${OS_SYSBIT}, this is domestic operate system"
        return 0
    fi

    if [ -z "$OS_PLATFORMID" ]; then
        return 1
    fi

    if [[ "${OS_PLATFORMID}" = *"kylin"* ]] || \
       [[ "${OS_PLATFORMID}" = *"uos"* ]] || [[ "${OS_PLATFORMID}" = *"deepin"* ]] || \
       [[ "${OS_PLATFORMID}" = *"nfs"* ]] || [[ "${OS_PLATFORMID}" = *"openeuler"* ]] || \
       [[ "${OS_PLATFORMID}" = *"euleros"* ]] || [[ "${OS_PLATFORMID}" = *"asianux"* ]] || \
       [[ "${OS_PLATFORMID}" = *"redflag"* ]] || [[ "${OS_PLATFORMID}" = *"linx"* ]] || \
       [[ "${OS_PLATFORMID}" = *"alinux"* && "${OS_PLATFORMID}" != *"almalinux"* ]] || [[ "${OS_PLATFORMID}" = *"anolis"* ]]; then
            echo "This operate system id is ${OS_PLATFORMID}, this is domestic operate system"
            return 0
    fi

	return 1
}

function checkip() { 
	regex="\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\b"
	ckStep2=`echo $1 | egrep $regex | wc -l`
	if [ $ckStep2 -eq 0 ]
	then
       return 1
	else
       return 0
	fi
}

#check regex,match return 1, no match return 0
function checkegrep()
{
    dest=$1
    regex_rule=$2
    ckStep2=`echo $dest | egrep $regex_rule | wc -l`
    if [ $ckStep2 -eq 0 ]
    then
        return 0
    else
        return 1
    fi
}

#check ip,dns,ipv6,match return 1，no match return 0
checkdest()
{
    #checkip
    regex_ip="\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[1-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\b"
    checkegrep $1 $regex_ip
    if [ $? -eq 1 ];then
        return 1
    fi
    #checkDns
    regex_dns="^[a-zA-Z]{1}[-a-zA-Z0-9]{0,61}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62}){2,3}$"
    checkegrep $1 $regex_dns
    if [ $? -eq 1 ];then
        return 1
    fi
    #check ipv6
    regex_ipv6_1="^((([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4})|(([0-9A-Fa-f]{1,4}:){1,7}:)|(([0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4})$"
    regex_ipv6_2="^(([0-9A-Fa-f]{1,4}:){5}(:[0-9A-Fa-f]{1,4}){1,2})|(([0-9A-Fa-f]{1,4}:){4}(:[0-9A-Fa-f]{1,4}){1,3})$"
    regex_ipv6_3="^(([0-9A-Fa-f]{1,4}:){3}(:[0-9A-Fa-f]{1,4}){1,4})|(([0-9A-Fa-f]{1,4}:){2}(:[0-9A-Fa-f]{1,4}){1,5})$"
    regex_ipv6_4="^([0-9A-Fa-f]{1,4}:(:[0-9A-Fa-f]{1,4}){1,6})|(:(:[0-9A-Fa-f]{1,4}){1,7})$"
    regex_ipv6_5="^(([0-9A-Fa-f]{1,4}:){6}(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})$"
    regex_ipv6_6="^(([0-9A-Fa-f]{1,4}:){5}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})$"
    regex_ipv6_7="^(([0-9A-Fa-f]{1,4}:){4}(:[0-9A-Fa-f]{1,4}){0,1}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}$"
    regex_ipv6_8="^2[0-4]\\d|25[0-5])){3})|(([0-9A-Fa-f]{1,4}:){3}(:[0-9A-Fa-f]{1,4}){0,2}:(\\d|[1-9]\\d|1\\d{2}$"
    regex_ipv6_9="^2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})$"
    regex_ipv6_10="^(([0-9A-Fa-f]{1,4}:){2}(:[0-9A-Fa-f]{1,4}){0,3}:(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})$"
    regex_ipv6_11="^([0-9A-Fa-f]{1,4}:(:[0-9A-Fa-f]{1,4}){0,4}:(\\d|[1-9]\\d|1\\d{2}$"
    regex_ipv6_12="^2[0-4]\\d|25[0-5])(\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])){3})$"
    regex_ipv6_13="^(:(:[0-9A-Fa-f]{1,4}){0,5}:(((\\d{1,2})|(1\\d{2})|(2[0-4]\\d)|(25[0-5]))\\.){3}((\\d{1,2})|(1\\d{2})|(2[0-4]\\d)|(25[0-5]))))$"
    checkegrep $1 $regex_ipv6_1
    if [ $? -eq 1 ];then
        return 1
    fi
    checkegrep $1 $regex_ipv6_2
    if [ $? -eq 1 ];then
        return 1
    fi
    checkegrep $1 $regex_ipv6_3
    if [ $? -eq 1 ];then
        return 1
    fi
    checkegrep $1 $regex_ipv6_4
    if [ $? -eq 1 ];then
        return 1
    fi
    checkegrep $1 $regex_ipv6_5
    if [ $? -eq 1 ];then
        return 1
    fi
    checkegrep $1 $regex_ipv6_6
    if [ $? -eq 1 ];then
        return 1
    fi
    checkegrep $1 $regex_ipv6_7
    if [ $? -eq 1 ];then
        return 1
    fi
    checkegrep $1 $regex_ipv6_8
    if [ $? -eq 1 ];then
        return 1
    fi
    checkegrep $1 $regex_ipv6_9
    if [ $? -eq 1 ];then
        return 1
    fi
    checkegrep $1 $regex_ipv6_10
    if [ $? -eq 1 ];then
        return 1
    fi
    checkegrep $1 $regex_ipv6_11
    if [ $? -eq 1 ];then
        return 1
    fi
    checkegrep $1 $regex_ipv6_12
    if [ $? -eq 1 ];then
        return 1
    fi
    checkegrep $1 $regex_ipv6_13
    if [ $? -eq 1 ];then
        return 1
    fi
    return 0
}


function checkport() {
	if [ -z $1 ];then
		return 1
	fi
	
	if [ $1 -gt 65535 ] || [ $1 -lt 1 ] ;then
		return 1
	fi
	return 0
}

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

# help
# -c for one-key deploy. the ipset interactive prompts will be ignored and installation packages will be automatically deleted.
# -e installing with HCI proxy
# -o full package installation
# -s check if the current OS is the one in 'support list'
# -u saseEdr enterprise id(in sase case)
return_usage() {
	echo -e "Usage: $0 [OPTION]..."
	echo -e "Example [1]: $0 \\033[40;31m(Use when there is manager_info.txt in the same directory)\\033[0m"
	echo -e "        [2]: $0 -h 8.8.8.8 -p 443 -f"
	echo -e "  -h host       set mgr host"
	echo -e "  -p port       set mgr port"
	echo -e "  -d dir        set absolute install dir"
	echo -e "  -f            force install"
	echo -e "  -c            slient install"
	echo -e "  -e            proxy install"
	echo -e "  -o            full package offline install"
	echo -e "  -s            system check"
	echo -e "  -u            saseEdr enterprise id"
	echo -e "  --help        display this help"
	exit $ERR_INVALID_PARAM
}

# 'root' permission is required when installing.
if [ `id -u` -ne 0 ];then
    echo -e "this installer script needs root permission"
	exit $ERR_ROOT_PRIVILIGE
fi

if [ -n "$1" ] && [ "$1" == "--help" ]; then
	return_usage
fi

force_install=0
slient_install=0
proxy_install=0
system_check=0
full_package_install=0

while getopts "h:p:d:u:fceso" opt; do
	case $opt in
		h)
			avai_ip=$OPTARG
			;;
		p)
			avai_port=$OPTARG
			;;
		d)
			installdir=$OPTARG
			;;
		f)
			force_install=1
			;;
		c)
			slient_install=1;
			;;
		o)
			full_package_install=1;
			;;
		e)
			proxy_install=1;
			;;
		s)
			system_check=1;
			;;
		u)
			szuid=$OPTARG
			;;
		\?)
			return_usage
			;;
	esac
done

# `ss` can be replaced if `netstat` is not exists
which netstat >/dev/null 2>&1
if [ $? -ne 0 ]; then
	NET_TOOL=ss
fi

# Note: this procedure must be called at the beginning, otherwise we cannot ensure that all the required tools are already present.
# before installation, all dependent tools are checked uniformly, and users are prompted to install the missing tools uniformly. 
# if you need to add a check dependency tool, add it here directly
check_tool grep iptables ip6tables iptables-restore iptables-save ip6tables-save sed awk df openssl wget crontab tar ${NET_TOOL}

len=${#need_tool[@]}

if [ $len -ne 0 ];then
    # echo "Installer asks tools bellow:" # echo "Installer asks tools as following:" 
	echo -e "\033[31m Installer asks tools bellow:\033[0m"
	for v in ${need_tool[@]};
	do
	    # echo "$v" 
		echo -e "\033[31m $v \033[0m"
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
	exit $ERR_COMMAND_MISS
fi

curr_dir=$(pwd)
ips_info=$curr_dir"/manager_info.txt"

uname -a | grep "x86_64" > /dev/null
if [ $? -ne 0 ] ; then
	echo "edr agent is installing on x86 machines"
	full_package=$curr_dir"/packages_86.tar.gz"
else
	echo "edr agent is installing on x86_64 machines"
	full_package=$curr_dir"/packages_64.tar.gz"
fi

function ReadINIfile()
{     
    Key=$1  
    Section=$2
    Configfile=$3
    ReadINI=`awk -F '=' '/\['$Section'\]/{a=1}a==1&&$1~/'$Key'/{print $2;exit}' $Configfile | tr -d " "`
    echo "$ReadINI"
}

if [ $full_package_install -ne 0 ];then
	# domain(or ip) and port are required when using full package installaion.
	if [ -z "$avai_ip" -o -z "$avai_port" ];then
		echo -e "\\033[40;31m The IP and PORT are missing during full-package offline installation.\\033[0m"
		return_usage
	fi

	# check offline components
	if [ ! -f $full_package ]; then
		echo -e "\\033[40;31m Not found full-package file: $full_package.\\033[0m"
		exit 1
	fi
fi

# allows use of the entered tenant id
# TD2023062000553: the full package is based on the input parameters and no longer reads files
if [ "${szuid}" == "" ] && [ $full_package_install -ne 1 ];then
	szuid=`ReadINIfile "tenant_id" "config" "$ips_info"`
	if [ "${szuid}" == "" ];then
		echo "invalid szuid."
	#	return 1
	fi
fi

echo "uid is $szuid."

if [ -z "$avai_ip" ];then
	bSucc=0
	if [ -f $ips_info ]; then
		addrCount=`ReadINIfile "count" "config" "$ips_info"`
		for((i=0; i<addrCount; i++))
		do
			Key="addr""$i"
			addr=`ReadINIfile "$Key" "config" "$ips_info"`
            checkdest $addr
			if [ $? -eq 0 ];then
			    #no mache ip or ipv6 or dns
				echo "no mache ip or ipv6 or dns"
				continue
			fi

			# perform connectivity check on the MGR
			test_ping=`ping $addr -c 3 -W 1`
			if [ $? -ne 0 ]; then
				echo "$addr can't be connected"
				continue
			else
				avai_ip=$addr
				bSucc=1
				echo "$avai_ip is available"
				break
			fi
		done
	fi
	if [ $bSucc != 1 ]; then
		return_usage
	fi
else
    checkdest $avai_ip
	if [ $? -eq 0 ];then
	    #no mache ip or ipv6 or dns
		echo "no mache ip or ipv6 or dns ,check your input ip or config"
		exit 1
	fi
fi

# full package don't check connection
if [ $full_package_install -ne 1 ];then
	# perform connectivity check on the MGR
	ping_test=`ping $avai_ip -c 3 -W 1`
	if [ $? -ne 0 ];then
		echo "manager addr:$avai_ip can't connect, please check your network."
		exit $ERR_NET_CONNECT
	fi
fi

if [ -z "$avai_port" ];then
	if [ -f $ips_info ]; then
		avai_port=`ReadINIfile "agt_download_port" "config" "$ips_info"`
	fi

	# manager.info is not exist in full package
	# docker env, default: 443
	# other env, default: 4430
	if [ -z $avai_port ];then
		if [ "${szuid}" == "" ];then
			avai_port=4430
		else 
			avai_port=443
		fi
	fi
fi
checkport $avai_port
if [ $? -ne 0 ]; then
	echo "Error: input params error, invalid port:$avai_port"
	return_usage
fi

if [ -f /etc/cron.d/eps_mgr -o -f /etc/cron.d/edr_mgr ]; then
	echo -e "\e[1;31mWarning:edr agent can not be installed on MGR.\e[0m"
	exit $ERR_INSTALL_POSITION
fi

if [ $force_install != 1 ]; then
	if [ -f /etc/cron.d/edr_agent ]; then
		echo "Warning:edr agent has been installed,do not install again."
		exit $ERR_ALREADY_INSTALL
	fi
fi

# abort installaion when avalible mem is less then 500M
mem_must=`expr 500 \* 1024`
mem_free=`cat /proc/meminfo |grep -w MemFree |awk -F " " '{print $2}'`
mem_buff=`cat /proc/meminfo |grep -w Buffers |awk -F " " '{print $2}'`
mem_cache=`cat /proc/meminfo |grep -w Cached |awk -F " " '{print $2}'`
mem_free_total=`expr $mem_free \+ $mem_buff \+ $mem_cache`
if [ $mem_free_total -lt $mem_must ]; then
	echo "Warning:system memory is less than 500M,installed failed."
	exit $ERR_MEMORY_SHORTAGE
fi

# make a flag, if the fold(/sf/edr/agent) is created by us, default_dir whold be 1
default_dir=0
if [ -z "$installdir" ]; then
	if [ ! -d /sf/edr/agent ];then
		default_dir=1
	fi
	installdir=/sf/edr/agent
fi

# create /tmp if not exists
if [ ! -d "/tmp" ]; then
	mkdir -p /tmp
fi

tmpdir=`mktemp -d /tmp/eps_agent.XXXXXX`
function die()
{
	echo -e $*
	rm -rf $tmpdir
	if [ $default_dir == 1 ];then
		rm -rf $installdir
	fi
	exit $2
}

checkIsGchOpSystem
if [ $? -eq 0 ]; then
    die "\nThe system is not supported. Please try using a domestic installation package" $ERR_UNSUPPORT_SYSTEM
fi

if [ $system_check == 1 ]; then
    checkOpSystem
    if [ $? -ne 0 ]; then
        die "\nunsupport system" $ERR_UNSUPPORT_SYSTEM
    fi
fi

mkdir -p $installdir || die "Can not mkdir $installdir" $ERR_INSTALL_PATH

# remove the last uninstalling flag
if [ -f /sf/edr/agent/bin/uninstalling ]; then
	rm -rf /sf/edr/agent/bin/uninstalling
fi

# backup agentid
if [ -f "/usr/share/sf/machineid" ]; then
	mkdir -p $installdir/config
	cp -f "/usr/share/sf/machineid" $installdir/config/
fi

# if default_dir_flag exists, when uninstalling, remove the install directory.
if [ $default_dir == 1 ];then
	touch $installdir/default_dir_flag
fi

# abort installaion when avalible disk space is less then 2.5G
disk_must=`expr 2 \* 1024 \* 1024 \+ 512 \* 1024`
avail_disk=`df / |grep / | sed -n '$p' |awk -F " " '{print $(NF-2)}'`
if [ $avail_disk -lt $disk_must ]; then
	die "space of disk / is less than 2.5G,installed failed." $ERR_MEMORY_SHORTAGE
fi


test "${installdir:0:1}" == "/" || die "Install dir must be a absolute path" $ERR_INSTALL_PATH

# one-key deploy ignore ipset command.
if [ $force_install != 1 ] && [ $slient_install != 1 ]; then
	which ipset > /dev/null
	if [ $? -ne 0 ]; then
		# the ipset command does not exist, issue a query
		read -p "Warn: The ipset has not been installed. You can exit this installer and install ipset first to improve performance. Do you want to continue installing the agent?[Y/N]" -n1 choice
		if [ "e$choice" != "eY" -a "e$choice" != "ey" ]; then
			die "\nWelcome install me again after you get ipset" $ERR_COMMAND_MISS
		else
			echo -e "\nWe will continue to install"
		fi
	fi
fi

# ============================== cron check start ==============================

# cron
function cron_change_inquiry() {
	# cron/crond not starting at boot-up, issue a query
	read -r -p "Warn: Cron not starting at boot-up. EDR need it to keep EDR running properly. Start cron at boot-up?[Y/N]" -n1 choice && echo
	if [[ "e$choice" != "eY" && "e$choice" != "ey" ]]; then
		die "Welcome install EDR again after you agree to change it." $ERR_CRON_SERVICE
	fi
}

# return Systemd
#        Upstart
#        Sysvinit
function system_init_check() {
	if systemctl --version >/dev/null 2>&1; then
		echo "systemd"
	elif initctl version >/dev/null 2>&1; then
		echo "upstart"
	else
		echo "sysvinit"
	fi
}

# configure service startup via systemd
#   $1: service (usually cron / crond)
function systemd_enable_service() {
	echo "systemd model"
	local rtn=$(systemctl status "$1")
	if [[ $rtn =~ "$1"".service; disabled" ]]; then
		cron_change_inquiry
		systemctl enable "$1"
	fi
}

# configure service startup via chkconfig
#   $1: service (usually cron / crond)
function chkconfig_enable_service() {
	echo "chkconfig model"
	local rtn=$(chkconfig --list | grep "$1")
	if [[ $rtn =~ "2:off" || $rtn =~ "3:off" ||
		  $rtn =~ "4:off" || $rtn =~ "5:off" ]]; then
		cron_change_inquiry
		chkconfig "$1" on
	fi
}

# configure service startup via upstart(only cron.)
function upstart_enable_service() {
	echo "upstart model"
	if [ ! -f "/etc/init/cron.conf" ]; then
		cron_change_inquiry
		(
			cat <<EOF
description     "regular background program processing daemon"

start on runlevel [2345]
stop on runlevel [!2345]

expect fork
respawn

exec cron
EOF
		) >"/etc/init/cron.conf"
	fi
}

# configure service startup via update-rc.d(only cron.)
function updatercd_enable_service() {
	echo "update-rc.d model"
	if [[ ! -f $(echo /etc/rc2.d/S[0-9][0-9]cron) ||
		  ! -f $(echo /etc/rc3.d/S[0-9][0-9]cron) ||
		  ! -f $(echo /etc/rc4.d/S[0-9][0-9]cron) ||
		  ! -f $(echo /etc/rc5.d/S[0-9][0-9]cron) ]]; then
		cron_change_inquiry
		update-rc.d cron enable
		update-rc.d cron defaults
	fi
}

# RedHat、CentOS、Oracle、NeoKylin
function redhat_enable_cron() {
	# echo "redhat"
	local rtn=$(system_init_check)
	if [[ $rtn == "systemd" ]]; then
		systemd_enable_service crond
	elif [[ $rtn == "sysvinit" ]]; then
		chkconfig_enable_service crond
	else
		echo "Warn: Bypass system init check"
	fi
}

# Ubuntu、UbuntuKylin、Kylin
function ubuntu_enable_cron() {
	# echo "ubuntu"
	local rtn=$(system_init_check)
	if [[ $rtn == "systemd" ]]; then
		systemd_enable_service cron
	elif [[ $rtn == "upstart" ]]; then
		upstart_enable_service
	else
		echo "Warn: Bypass system init check"
	fi
}

# Debian
function debian_enable_cron() {
	# echo "debian"
	local rtn=$(system_init_check)
	if [[ $rtn == "systemd" ]]; then
		systemd_enable_service cron
	elif [[ $rtn == "sysvinit" ]]; then
		updatercd_enable_service
	else
		echo "Warn: Bypass system init check"
	fi
}

# SUSE
function suse_enable_cron() {
	# echo "suse"
	local rtn=$(system_init_check)
	if [[ $rtn == "systemd" ]]; then
		systemd_enable_service cron
	elif [[ $rtn == "sysvinit" ]]; then
		chkconfig_enable_service cron
	else
		echo "Warn: Bypass system init check"
	fi
}

function clean() {
	`rm -rf $SCRIPT_PATH/linux_aes_installer* >/dev/null 2>&1`
	`rm -rf $SCRIPT_PATH/sfupdate* >/dev/null 2>&1`
	`rm -rf $SCRIPT_PATH/manager_info.txt >/dev/null 2>&1`
	`rm -rf $SCRIPT_PATH/agent_installer.sh >/dev/null 2>&1`
	`rm -rf $SCRIPT_PATH/readme.txt >/dev/null 2>&1`
}

if [ ! -f /usr/sbin/cron ] && [ ! -f /usr/sbin/crond ]; then
	die "Error: Unable to find cron. EDR need it to keep EDR running properly." $ERR_CRON_SERVICE
fi

# load $lsb
lsb=$(lsb_release -a 2>&1)

# load $PRETTY_NAME
if [ -f /etc/os-release ]; then
	source /etc/os-release
fi

if [ -f /etc/redhat-release ]; then
	redhat_enable_cron
elif [[ $lsb =~ "Ubuntu" || $PRETTY_NAME =~ "Ubuntu" ]]; then
	ubuntu_enable_cron
elif [[ $lsb =~ "Debian" || $PRETTY_NAME =~ "Debian" ]]; then
	debian_enable_cron
elif [[ $lsb =~ "SUSE" || $PRETTY_NAME =~ "SUSE" ]]; then
	suse_enable_cron
elif [[ $lsb =~ "NeoKylin" || $PRETTY_NAME =~ "NeoKylin" ]]; then
	redhat_enable_cron
elif [[ $lsb =~ "Kylin" || $PRETTY_NAME =~ "Kylin" ]]; then
	ubuntu_enable_cron
else
	echo "Warn: Bypass system check"
fi

# Redhat
if [ -f /usr/sbin/crond ]; then
	service crond start >/dev/null 2>&1
fi

# not Redhat
if [ -f /usr/sbin/cron ]; then
	service cron start >/dev/null 2>&1
fi

# =============================== cron check end ===============================

function full_package_unzip()
{
	local packages_path=$1
	local install_path=$2
	
	if [ ! -d "${install_path}" ];then
		mkdir -p ${install_path}
	else
		rm -rf ${install_path}
		mkdir -p ${install_path}
	fi
	
	tar -zxvf ${packages_path} -C ${install_path} >/dev/null 2>&1
}

longtype_length=`getconf LONG_BIT`
sfupdate="${SCRIPT_PATH}/sfupdate64.bin"
if [ $longtype_length -eq 32 ]; then
	sfupdate="${SCRIPT_PATH}/sfupdate32.bin"
fi
chmod +x $sfupdate
echo "start download edr module"
tempdir=${installdir##*sf}
if [[ $tempdir != "/edr/agent" && $tempdir != "/edr/agent/" ]];then
	lastChar=${installdir: -1}
	if [ $lastChar != "/" ];then
		installdir=$installdir"/sf/edr/agent"
	else
		installdir=$installdir"sf/edr/agent"
	fi
fi

# G2HProxy
if [ $proxy_install -eq 1 ]; then
	# check whether the proxy port is occupied
	value=`${NET_TOOL} -tunlp|grep "${G2HPorxyIP}:${G2HProxyPort}"`
	if [ $? -eq 0 ];then
		echo $value | grep "${G2HProxyName}" >/dev/null 2>&1
		if [ $? -ne 0 ];then
			die "G2HProxy port was occupied" $ERR_G2H_PORT_OCCUPIED
		fi
	fi
	avai_ip=$G2HPorxyIP
	avai_port=$G2HProxyPort
fi

mkdir -p $installdir/bin > /dev/null 2>&1
cp $sfupdate $installdir/bin/sfupdate
if [ $? -ne 0 ];then
	die "cp sfupdate fail."
fi

INSTALL_RUNNING_FLAG=$installdir/bin/install_running_flag
touch ${INSTALL_RUNNING_FLAG}

if [ "$szuid" = "" ]; then
	echo "curr install path: $installdir url:https://${avai_ip}:${avai_port}"
	if [ "$full_package_install" -ne 0 ];then
		# full package installation
		full_package_unzip $full_package $installdir/packages
		$sfupdate -a "https://${avai_ip}:${avai_port}" -d $installdir -b 0 -w
	else
		$sfupdate -a "https://${avai_ip}:${avai_port}" -d $installdir -c -b 0
	fi
	
else
	echo "curr install path: $installdir url:https://${avai_ip}:${avai_port} uid :$szuid"
	if [ $full_package_install -ne 0 ];then
		# full package installation
		full_package_unzip $full_package $installdir/packages
		$sfupdate -a "https://${avai_ip}:${avai_port}" -d $installdir -u $szuid -b 0 -w
	else
		$sfupdate -a "https://${avai_ip}:${avai_port}" -d $installdir -c -u $szuid -b 0
	fi
fi

exit_code=$?
if [ $exit_code -ne 0 ];then
	rm -f ${INSTALL_RUNNING_FLAG}
	die "download edr module fail." $exit_code
fi

SERVICE_NAME="eps_services"
EpsServicesPath=$installdir/bin/$SERVICE_NAME

if [ -f "${EpsServicesPath}" ];then
    ${EpsServicesPath} restart
fi

# clean files when slient installing is ended.
if [ $slient_install -eq 1 ]; then
	clean
fi

rm -f ${INSTALL_RUNNING_FLAG}
echo "download edr module success"

