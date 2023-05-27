#!/bin/bash
# OS安装识别脚本
# Author: Slotheve<https://slotheve.com>

checkSystem() {
    result=$(id | awk '{print $1}')
    if [[ $result != "uid=0(root)" ]]; then
        result=$(id | awk '{print $1}')
	if [[ $result != "用户id=0(root)" ]]; then
        colorEcho $RED " 请以root身份执行该脚本"
        exit 1
	fi
    fi

    res=`which yum 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        res=`which apt 2>/dev/null`
        if [[ "$?" != "0" ]]; then
            colorEcho $RED " 不受支持的Linux系统"
            exit 1
        fi
        PMT="apt"
        CMD_INSTALL="apt install -y "
        CMD_UPGRADE="apt update; apt autoremove -y"
    else
        PMT="yum"
        CMD_INSTALL="yum install -y "
        CMD_UPGRADE="yum update -y"
    fi
    res=`which systemctl 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        colorEcho $RED " 系统版本过低，请升级到最新版本"
        exit 1
    fi
}

DNS=(
cloudflare
dnspod
Aliyun
Google
OVH
Gandi
DnsSimple
DigitalOcean

)

selectDNS() {
	for ((i=1;i<=${#ciphers[@]};i++ )); do
		hint="${ciphers[$i-1]}"
		echo -e "${green}${i}${plain}) ${hint}"
	done
	read -p "你选择什么加密方式(默认: ${ciphers[0]}):" pick
	[ -z "$pick" ] && pick=1
	expr ${pick} + 1 &>/dev/null
	if [ $? -ne 0 ]; then
		echo -e "[${red}Error${plain}] Please enter a number"
		continue
	fi
	if [[ "$pick" -lt 1 || "$pick" -gt ${#ciphers[@]} ]]; then
		echo -e "${BLUE}[${PLAIN}${RED}Error${PLAIN}${BLUE}]${PLAIN} ${BLUE}请正确选择${PLAIN}"
		exit 0
	fi
	METHOD=${ciphers[$pick-1]}
	colorEcho $BLUE " 加密：${ciphers[$pick-1]}"
}

$CMD_UPGRADE && $CMD_INSTALL certbot $PLUGIN
