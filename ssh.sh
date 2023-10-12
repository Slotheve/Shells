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

Install() {
  read -p $'请输入需要设置的端口:' PORT
  echo $((${PORT}+0)) &>/dev/null
  if [[ $? -eq 0 ]]; then
      if [[ ${PORT} -ge 1 ]] && [[ ${PORT} -le 65535 ]]; then
          colorEcho $BLUE "SSH端口: ${PORT}"
          echo ""
      else
          colorEcho $RED "输入错误, 请输入正确的端口。"
          echo ""
      fi
  else
      colorEcho $RED "输入错误, 请输入数字。"
      echo ""
      exit 1
  fi
  sed -i '/Port 22/d' /etc/ssh/sshd_config 
  sed -i '/PubkeyAuthentication/d' /etc/ssh/sshd_config 
  sed -i '/PasswordAuthentication/d' /etc/ssh/sshd_config 
  echo "Port $PORT" >> /etc/ssh/sshd_config 
  echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config 
  echo "PasswordAuthentication no" >> /etc/ssh/sshd_config 
  systemctl restart sshd
  colorEcho $BLUE " 安装完成"
}

checkSystem
Install
