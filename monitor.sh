#! /bin/bash
########################################################
# Author : Fouad JADOUANI <fouad.j [at] live [dot] fr>
# Usage  : ./monitor.sh
# Description : script allow to have some esesntial information about OS 
# Created : 11/09/2016
# Version : 1.0
# License : MIT
###############

echo "OS Type:" $(uname -o)
echo "OS Name:" $(cat /etc/os-release | grep ^VERSION= | cut -f2 -d\")
echo "OS Version:" $(cat /etc/os-release | grep ^NAME= | cut -f2 -d\")
echo "Architecture:" $(uname -m)
echo "Kernel Release:" $(uname -r)
echo "Load Average: $(cat /proc/loadavg | cut -f 1-3 -d ' ')"
echo "System Uptime:" $(uptime -p | cut -f 2- -d " ")
echo "Hostname:" $HOSTNAME
echo "Internal IP:" $(hostname -I)
echo "External IP:" $(wget http://ipinfo.io/ip -qO -)
echo "Name Servers:" $(cat /etc/resolv.conf | grep 'nameserver' | awk '{print $2}')
echo -e "Logged In users:\n$(who)"
echo -e "Memory Usages(Mo):\n$(free -m | grep -v +)"
echo -e "Disk Usages:\n$(df -h| grep 'Filesystem\|^/dev/*')"
