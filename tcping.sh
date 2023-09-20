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
          res=`which apk 2>/dev/null`
          if [[ "$?" != "0" ]]; then
            colorEcho $RED " 不受支持的Linux系统"
            exit 1
          fi
        fi
    fi
    res=`which systemctl 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        colorEcho $RED " 系统版本过低，请升级到最新版本"
        exit 1
    fi
}

archAffix() {
    case "$(uname -m)" in
        x86_64|amd64)
            ARCH="amd64"
        ;;
        armv8|aarch64)
            ARCH="arm64"
        ;;
        *)
            colorEcho $RED " 不支持的CPU架构！"
            exit 1
        ;;
    esac

	return 0
}

Install() {
	checkSystem
 	archAffix
	wget --no-check-certificate -O /usr/bin/tcping https://raw.githubusercontent.com/Slotheve/backup/main/tcping-$ARCH
	chmod +x /usr/bin/tcping
  colorEcho $BLUE " 安装完成"
}

checkSystem
Install
