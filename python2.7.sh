#!/bin/bash

RED="\033[31m"
BLUE="\033[36m"
PLAIN='\033[0m'

colorEcho() {
    echo -e "${1}${@:2}${PLAIN}"
}

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
        CMD_INSTALL="apt install -y"
        CMD_AUTOREMOVE="apt autoremove -y"
        CMD_UPGRADE="apt update"
    else
        PMT="yum"
        CMD_INSTALL="yum install -y"
        CMD_UPGRADE=""
    fi
    res=`which systemctl 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        colorEcho $RED " 系统版本过低，请升级到最新版本"
        exit 1
    fi
}

Install() {
    $CMD_UPGRADE
    $CMD_INSTALL python2.7
    wget -N --no-check-certificate https://raw.githubusercontent.com/Slotheve/backup/main/pip2.py
    python2.7 pip2.py && rm pip2.py >/dev/null
    colorEcho $BLUE " 安装完成"
}

checkSystem
Install
