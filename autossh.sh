#!/bin/bash
# AutoSSH一键脚本
# Author: Slotheve<https://slotheve.com>

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[36m"
PLAIN='\033[0m'

SSHFILE="/etc/ssh/sshd_config"

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
	      CMD_REMOVE="apt remove -y"
    else
        PMT="yum"
        CMD_INSTALL="yum install -y"
	      CMD_REMOVE="yum remove -y"
    fi
    res=`which systemctl 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        colorEcho $RED " 系统版本过低，请升级到最新版本"
        exit 1
    fi
}

Install() {
    checkSystem
    $CMD_UPGRADE && $CMD_AUTOREMOVE && $CMD_INSTALL autossh lsof
    mkdir -p /etc/autossh
    cat > /etc/autossh/penetrate.sh << EOF
#!/bin/bash

printf "%-24s %-20s %-4s\n" 远程IP地址 本地端口 远程端口
EOF
}

SetSSH() {
    read -p " 请输入远程机IP：" IP
    colorEcho ${BLUE}  " $IP"
    read -p " 请输入远程机SSH端口：" PORT
    colorEcho ${BLUE}  " $PORT"
    ssh root@$IP -p $PORT -o "StrictHostKeyChecking no" \
       "echo 'GatewayPorts yes' >> $SSHFILE; \
        echo 'TCPKeepAlive yes' >> $SSHFILE; \
        echo 'ClientAliveInterval 60' >> $SSHFILE; \
        echo 'ClientAliveCountMax 3' >> $SSHFILE; \
        systemctl restart sshd"
}

SetPort() {
    read -p " 请输入本机监听端口：" PORT1
    [[ -z "${PORT1}" ]] && PORT1=`shuf -i40000-65000 -n1`
    if [[ "${PORT:0:1}" = "0" ]]; then
        colorEcho ${RED}  " 端口不能以0开头"
        exit 1
    fi
    colorEcho ${BLUE}  " $PORT1"
    read -p " 请输入本机需穿透端口：" PORT2
    colorEcho ${BLUE}  " $PORT2"
    read -p " 请输入远程机映射端口：" PORT3
    [[ -z "${PORT3}" ]] && PORT3=`shuf -i40000-65000 -n1`
    if [[ "${PORT:0:1}" = "0" ]]; then
        colorEcho ${RED}  " 端口不能以0开头"
        exit 1
    fi
    colorEcho ${BLUE}  " $PORT3"
    read -p " 请输入远程机IP：" IP
    colorEcho ${BLUE}  " $IP"
    read -p " 请输入远程机SSH端口：" PORT4
    colorEcho ${BLUE}  " $PORT4"

    cat > /etc/systemd/system/autossh-$IP-$PORT2.service << EOF
[Unit]
Description=AutoSSH-$PORT2
After=network-online.target

[Service]
User=root
ExecStart=/usr/bin/autossh -M $PORT1 -NR $PORT3:127.0.0.1:$PORT2 root@$IP -p $PORT4 -o "StrictHostKeyChecking no"
Restart=always
 
[Install]
WantedBy=multi-user.target
EOF

    cat >> /etc/autossh/penetrate.sh << EOF
printf "%-20s %-16s %-5s\n" $IP $PORT2 $PORT3
EOF

    systemctl daemon-reload
    systemctl enable autossh-$IP-$PORT2
    systemctl start autossh-$IP-$PORT2
    RES=`lsof -i:$PORT1`
    if [[ ! -n "$RES" ]]; then
        colorEcho ${YELLOW}  " 安装完成, 穿透后信息$IP-$PORT3"
    else
	      colorEcho ${YELLOW}  " 安装失败, 请检查端口是否冲突"
    fi
}

List() {
    JUDGE=`grep 5s /etc/autossh/penetrate.sh`
    if [[ -n "$JUDGE" ]]; then
        bash /etc/autossh/penetrate.sh
    else
        colorEcho ${RED}  " 未设置穿透"
    fi
}

Remove() {
    List
    read -p "请输入远程IP地址：" IP
    read -p "请输入本地端口：" PORT
    eval sed -i '/"$IP $PORT"/d' /etc/autossh/penetrate.sh
    systemctl disable autossh-$IP-$PORT
    systemctl stop autossh-$IP-$PORT
    rm -rf /etc/systemd/system/autossh-$IP-$PORT.service
    systemctl daemon-reload
    bash /etc/autossh/penetrate.sh
    colorEcho ${BLUE}  "已成功移除"
}

UnInstall() {
    checkSystem
    echo ""
    read -p " 确定卸载AutoSSH？[y/n]：" answer
    if [[ "${answer,,}" = "y" ]]; then
        rm -rf /etc/systemd/system/autossh*.service
        systemctl daemon-reload
	      $CMD_REMOVE autossh
        colorEcho $GREEN " autossh卸载成功"
    fi
}

menu() {
	clear
	echo "######################################"
	echo -e "#         ${RED}AutoSSH一键脚本${PLAIN}            #"
	echo -e "#    ${GREEN}作者${PLAIN}: 怠惰(Slotheve)            #"
	echo -e "#    ${GREEN}网址${PLAIN}: https://slotheve.com      #"
	echo -e "#    ${GREEN}TG群${PLAIN}: https://t.me/slotheve     #"
	echo "######################################"
	echo " -------------------"
  echo -e "  ${GREEN}1.${PLAIN}  安装AutoSSH"
	echo -e "  ${GREEN}2.${PLAIN}    设置穿透"
  echo -e "  ${GREEN}3.${PLAIN}  列出穿透列表"
	echo -e "  ${GREEN}4.${PLAIN}    移除穿透"
  echo -e "  ${GREEN}5.${PLAIN}  ${RED}卸载AutoSSH${PLAIN}"
	echo -e "  ${GREEN}6.${PLAIN}设置SSH${RED} (必要步骤)${PLAIN}"
	echo " -------------------"
	echo -e "  ${GREEN}0.${PLAIN}     退出"
	echo ""
	echo 

	read -p " 请选择操作[0-4]：" answer
	case $answer in
		0)
			exit 0
			;;
		1)
			Install
			;;
		2)
			SetPort
			;;
		3)
			List
			;;
		4)
			Remove
			;;
		5)
			UnInstall
			;;
		6)
			SetSSH
			;;
		*)
			colorEcho $RED " 请选择正确的操作！"
			exit 1
			;;
	esac
}

checkSystem
menu
