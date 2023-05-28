#!/bin/bash
# Frp一键脚本
# Author: Slotheve<https://slotheve.com>

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[36m"
PLAIN='\033[0m'

IP=`curl -sL -4 ip.sb`

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
	      CMD_AUTO="apt autoremove -y"
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

Arch() {
    case "$(uname -m)" in
        i686|i386)
            echo '386'
        ;;
        x86_64|amd64)
            echo 'amd64'
        ;;
        armv5tel)
            echo 'arm'
        ;;
        armv6l)
            echo 'arm'
        ;;
        armv7|armv7l)
            echo 'arm'
        ;;
        armv8|aarch64)
            echo 'arm64'
        ;;
        mips64le)
            echo 'mips64le'
        ;;
        mips64)
            echo 'mips64'
        ;;
        mipsle)
            echo 'mipsle'
        ;;
        mips)
            echo 'mips'
        ;;
        riscv64)
            echo 'riscv64'
        ;;
        *)
            colorEcho $RED " 不支持的CPU架构！"
            exit 1
        ;;
    esac

	return 0
}

GetInfo() {
    read -p "请输入服务端监听TCP端口：" PORT1
    colorEcho ${BLUE} "端口: $PORT1"
    read -p "请输入为HTTP类型代理监听的端口：" PORT2
    colorEcho ${BLUE} "端口: $PORT2"
    read -p "请输入鉴权使用的Token：" TOKEN
    colorEcho ${BLUE} "Token: $TOKEN"
    read -p "是否启用Web面板？[y/n]：" answer
    if [[ "${answer,,}" = "y" ]]; then
        colorEcho ${BLUE} "开启面板"
        read -p "请输入服务端Web面板端口：" PORT3
        read -p "请输入服务端Web面板用户名：" USER
        read -p "请输入服务端Web面板密码：" PASS
        Dash
        WEB="Y"
    else
        colorEcho ${BLUE} "关闭面板"
        noDash
        WEB="N"
    fi
}

Dash() {
    cat > /etc/frp/frp.ini << EOF
[common]
# PORT
bind_addr = 0.0.0.0
bind_port = $PORT1
kcp_bind_port = $PORT1
vhost_http_port = $PORT2
# DASH
dashboard_addr = 0.0.0.0
dashboard_port = $PORT3
dashboard_user = $USER
dashboard_pwd = $PASS
# LOG
log_file = ./frp.log
log_level = info
log_max_days = 3
disable_log_color = false
detailed_errors_to_client = true
# AUTH
authentication_method = token
authenticate_heartbeats = false
authenticate_new_work_conns = false
token = $TOKEN
# LIMIT
max_pool_count = 5
max_ports_per_client = 0
EOF
}

noDash() {
    cat > /etc/frp/frp.ini << EOF
[common]
# PORT
bind_addr = 0.0.0.0
bind_port = $PORT1
kcp_bind_port = $PORT1
vhost_http_port = $PORT2
# LOG
log_file = ./frp.log
log_level = info
log_max_days = 3
disable_log_color = false
detailed_errors_to_client = true
# AUTH
authentication_method = token
authenticate_heartbeats = false
authenticate_new_work_conns = false
token = $TOKEN
# LIMIT
max_pool_count = 5
max_ports_per_client = 0
EOF
}

Install_1() {
    API="https://api.github.com/repos/fatedier/frp/releases/latest"
    VER="$(normalizeVersion "$(curl -s "${API}" --connect-timeout 10| grep -Eo '\"tag_name\"(.*?)\",' | cut -d\" -f4 | cut -d v -f2)")"
    DOWNLOAD_LINK="https://github.com/fatedier/frp/releases/download/v${VER}/frp_${VER}_linux_$(Arch).tar.gz"
    mkdir -p /etc/frp
    $CMD_UPDATE && $CMD_AUTO && $CMD_INSTALL wget tar openssl
    curl -L -H "Cache-Control: no-cache" ${DOWNLOAD_LINK}
    tar -xzvf frp_${VER}_linux_$(Arch).tar.gz
    rm -rf frp_${VER}_linux_$(Arch).tar.gz
    cd frp_${VER}_linux_$(Arch)
    cp frps /usr/local/bin/frp
    chmod +x /usr/local/bin/frp
    touch /etc/frp/frp.ini
    chmod +x /etc/frp/frp.ini
    GetInfo

    cat > /etc/systemd/system/frp.service << EOF
[Unit]
Description=frp service
Requires=network.target network-online.target
After=network.target network-online.target

[Service]
Type=simple
PIDFile=/tmp/frp.pid
ExecStart=/usr/local/bin/frp -c /etc/frp/frp.ini
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable frp
    systemctl start frp >/dev/null 2>&1
    RES=`lsof -i:$PORT1`
    if [[ ! -n "$RES" ]]; then
        if   [[ "$WEB" = "Y" ]]; then
            echo -e "${BLUE}安装完成, 请在浏览器输入${PLAIN} ${YELLOW}http://${IP}:${PORT3}${PLAIN} ${BLUE}打开Web面板${PLAIN}"
        elif [[ "$WEB" = "N" ]]; then
            colorEcho ${BLUE} "安装完成"
        fi
    else
        colorEcho ${YELLOW} "安装失败, 请检查端口是否冲突"
    fi
}

Edit_1() {
    GetInfo
    systemctl restart frp >/dev/null 2>&1
    RES=`lsof -i:$PORT1`
    if [[ ! -n "$RES" ]]; then
        colorEcho ${BLUE} "修改完成"
    else
        colorEcho ${YELLOW} "端口冲突, 请重新修改"
    fi
}

Install_2() {
    API="https://api.github.com/repos/fatedier/frp/releases/latest"
    VER="$(normalizeVersion "$(curl -s "${API}" --connect-timeout 10| grep -Eo '\"tag_name\"(.*?)\",' | cut -d\" -f4 | cut -d v -f2)")"
    DOWNLOAD_LINK="https://github.com/fatedier/frp/releases/download/v${VER}/frp_${VER}_linux_$(Arch).tar.gz"
    mkdir -p /etc/frp
    $CMD_UPDATE && $CMD_AUTO && $CMD_INSTALL wget vim nano tar openssl
    curl -L -H "Cache-Control: no-cache" ${DOWNLOAD_LINK}
    tar -xzvf frp_${VER}_linux_$(Arch).tar.gz
    rm -rf frp_${VER}_linux_$(Arch).tar.gz
    cd frp_${VER}_linux_$(Arch)
    cp frpc /usr/local/bin/frp
    chmod +x /usr/local/bin/frp
    touch /etc/frp/frp.ini
    chmod +x /etc/frp/frp.ini

   cat > /etc/frp/frp.ini << EOF
[common]
server_addr = 0.0.0.0
server_port = 7000
authentication_method = token

[range:tcp_port]
type = tcp
local_ip = 127.0.0.1
local_port = 6010-6020,6022,6024-6028
remote_port = 6010-6020,6022,6024-6028 
use_encryption = false # 加密
use_compression = false # 压缩

[web01]
type = http
local_ip = 127.0.0.1
local_port = 80
remote_port = 46690
custom_domains = web01.yourdomain.com
use_encryption = false
use_compression = true
EOF

    cat > /etc/systemd/system/frp.service << EOF
[Unit]
Description=frp service
Requires=network.target network-online.target
After=network.target network-online.target

[Service]
Type=simple
PIDFile=/tmp/frp.pid
ExecStart=/usr/local/bin/frp -c /etc/frp/frp.ini
ExecReload=/usr/local/bin/frp reload -c /home/***/frp/frpc.ini
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable frp
    systemctl start frp
    colorEcho ${YELLOW}  "安装完成"
}

Edit_2() {
    colorEcho ${YELLOW} "编辑完成请执行 systemctl restart frp"
    read -p "请选择编辑器 1 (vim) 或 2 (nano)：" answer
    if   [[ "${answer,,}" = "1" ]]; then
        vim /etc/frp/frp.ini
    elif [[ "${answer,,}" = "2" ]]; then
        nano /etc/frp/frp.ini
    fi
}

Uninstall() {
    read -p " 确定卸载frp？[y/n]：" answer
    if [[ "${answer,,}" = "y" ]]; then
        systemctl stop xray
        systemctl disable xray
        rm -rf /etc/systemd/system/frp.service
        systemctl daemon-reload
        rm -rf /etc/frp
        colorEcho $GREEN " frp卸载成功"
    fi
}

menu() {
	clear
	echo "######################################"
	echo -e "#         ${RED}FRP一键脚本${PLAIN}            #"
	echo -e "#    ${GREEN}作者${PLAIN}: 怠惰(Slotheve)            #"
	echo -e "#    ${GREEN}网址${PLAIN}: https://slotheve.com      #"
	echo -e "#    ${GREEN}TG群${PLAIN}: https://t.me/slotheve     #"
	echo "######################################"
	echo " --------------"
  echo -e "  ${GREEN}1.${PLAIN}  安装FRPS"
  echo -e "  ${GREEN}2.${PLAIN}  修改FRPS"
  echo -e "  ${GREEN}3.${PLAIN}  安装FRPC"
  echo -e "  ${GREEN}4.${PLAIN}  编辑FRPC"
  echo -e "  ${GREEN}5.${PLAIN}  ${RED}卸载FRP${PLAIN}"
	echo " --------------"
	echo -e "  ${GREEN}0.${PLAIN}    退出"
	echo ""
	echo 

	read -p " 请选择操作[0-4]：" answer
	case $answer in
		0)
			exit 0
			;;
		1)
			Install_1
			;;
		2)
			Edit_1
			;;
		3)
			Install_2
			;;
		4)
			Edit_2
			;;
		5)
			Uninstall
			;;
		*)
			colorEcho $RED " 请选择正确的操作！"
			exit 1
			;;
	esac
}

checkSystem
menu
