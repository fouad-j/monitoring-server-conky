#! /bin/bash
########################################################
# Author : Fouad JADOUANI <fouad.j [at] live [dot] fr>
# Usage  : ./server_info.sh -s severName [-t refreshRate] cmd...
# Description : script allow to format data returned by monitor.sh
# Created : 11/09/2016
# Version : 1.0
# License : MIT
###############

set -u

# Command and his appearance line
declare -A infos=([osType]=1 [osName]=2 [osVersion]=3 [architecture]=4 [kernel]=5 [loadAverage]=6 \
				  [upTime]=7 [hostName]=8 [externalIp]=9 [internalIp]=10 [nameServers]=11);

# Servers
declare -A servers=([pi]='pi@pi' [integration]='fouad@integration' [lisa]='ubuntu@lisa-prod');

function usage {
	cat <<- FIN
		Usage : $0 -s severName [-t refreshRate] cmd...
		Options:
		    -s   Server name
		    -t   Refresh rate (by second)
		    -h   Display help and exit
	FIN
}

server="";
refreshRate=3000;
OPTERR=0;

while getopts ":s:t:h" arg ; do
	case $arg in
		s )
			case "$OPTARG" in
				"lisa"|"pi"|"integration") server=$OPTARG ;;
				*) echo "Error: unknown server" >&2; exit 1 ;;
			esac
		;;
		t )
			if echo $OPTARG | grep -E "^[0-9]+$" > /dev/null 2>&1 ; then 
				refreshRate=$OPTARG;
			else
				echo "-f argument must be a number" >&2; exit 1;
			fi
		;;
		h ) usage; exit 0 ;;
		: ) echo "Missed argument for -$OPTARG" >&2; usage; exit 1 ;;
		? ) echo "Unknown option -$OPTARG" >&2; usage; exit 1 ;;
	esac
done

shift $((OPTIND - 1));

if [ -z "$server" ] ; then
	echo "Missed '-s nameServer' option" >&2; usage; exit 1;
fi

if [ $# == '0' ] ; then
	echo "You must provide at least one cmd" >&2; usage; exit 1;
fi

function fetchInfoServer {
	pathConky="$( cd "$(dirname "$0")" ; pwd -P )"
	
	# create a log directory
	if [ ! -d "$pathConky/log" ]; then
		mkdir -p $pathConky/log
	fi
	
	# get latest file for this server

	fileName=$(ls -1At ${pathConky}/log/${1}-* 2> /dev/null | head -1);

	# check if no file exist for this server in log folder or if it has over than refreshRate
	if [[ -z "$fileName" || $(( `date +%s` - `stat -L --format %Y $fileName` )) -gt "$refreshRate" ]] ; then
		fileName="${pathConky}/log/${1}-$(date +'%b-%d-%y--%H-%M')";

		monitorFile=$(cat $pathConky/monitor.sh);
		
		# if monitor.sh doesn't exist in our server else we create and execut it
		echo "$monitorFile" | ssh -q -p 2122 ${servers[$1]} '[[ ! -f ".monitor.sh" ]] && cat > .monitor.sh; bash .monitor.sh' > $fileName
	fi
}

fetchInfoServer $server

for i in $@; do
	case $i in
		"osType"|"osName"|"osVersion"|"architecture"|"kernel"|"loadAverage"|"upTime"|"hostName"|"externalIp"|"internalIp"|"nameServers")
			echo $(sed -n ${infos[$i]}p $fileName | cut -d ':' -f2) 
		;;
		"ram") 			 
			echo $(sed -n '/^Memory/,/^Disk/{ /^Memory/d; /^Disk/d; /^Mem:/p }'< $fileName | \
			awk '{printf("%-2d%% %.2fG/%.2fG\n", $3/$2 * 100.0, $3/1024, $2/1024)}') 
		;;
		"ramPercent") 
			echo $(sed -n '/^Memory/,/^Disk/{ /^Memory/d; /^Disk/d; /^Mem:/p }'< $fileName | \
			awk '{printf("%-2d\n", $3/$2 * 100.0)}')
		;;
		"swap")
			echo $(sed -n '/^Memory/,/^Disk/{ /^Memory/d; /^Disk/d; /^Swap:/p }'< $fileName| \
			awk '{printf("%-2d%% %.2fG/%.2fG\n", ($2!=0) ? $3/$2*100.0 : 0, $3/1024, $2/1024)}')
		;;
		"swapPercent")
			echo $(sed -n '/^Memory/,/^Disk/{ /^Memory/d; /^Disk/d; /^Swap:/p }'< $fileName| \
			awk '{printf("%-2d\n", ($2!=0) ? $3/$2*100.0 : 0)}') 
		;;
		"loggedInUsers") echo $(sed -n '/^Logged In/,/^Memory/{ /^Logged In/d; /^Memory/d; p }' < $fileName) ;;
		"disks") 		 echo "$(sed -n '/^Filesystem/,$p'< $fileName)" ;;
		*) 				 echo "Error: unknown cmd" >&2; exit 1;
	esac
done
