#!/bin/bash
# OS安装识别脚本
# Author: Slotheve<https://slotheve.com>

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[36m"
PLAIN='\033[0m'

CertPath="/etc/letsencrypt/live/"
CRON="/etc/cron.d/certbot"

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
        CMD_INSTALL="apt update && apt autoremove -y && apt install -y "
    else
        PMT="yum"
        CMD_INSTALL="yum install -y "
    fi
    res=`which systemctl 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        colorEcho $RED " 系统版本过低，请升级到最新版本"
        exit 1
    fi
}

Install() {
    if   [[ $PMT = "apt" ]]; then
        DNS="python3-certbot-dns-cloudflare"
    elif [[ $PMT = "yum" ]]; then
        DNS="python2-certbot-dns-cloudflare"
    fi
    $CMD_INSTALL certbot $DNS
    touch /etc/letsencrypt/cloudflare.ini
    
    read -p " 请输入CloudFlare邮箱: " MAIL
    read -p " 请输入CloudFlare Global api：" KEY
    cat > /etc/letsencrypt/cloudflare.ini << EOF
dns_cloudflare_email = $MAIL
dns_cloudflare_api_key = $KEY
EOF
    chmod 600 /etc/letsencrypt/cloudflare.ini
    echo -e " ${YELLO}安装完成${PLAIN}"
}

ApplyCert() {
    echo -e " ${BLUE}首次申请需要填写邮箱并同意协议, 前几次失败很正常, 请尝试重新申请${PLAIN}"
    read -p " 请输入域名, 若有多个域名, 请使用','隔开：" DOMAIN
    certbot certonly --dns-cloudflare \
      --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
      -d $DOMAIN
}

CopyCert() {
    read -p " 请输入域名 (泛域名请输入xxxx.com) ：" DOMAIN
    read -p " 请输入安装路径：" PATH

    cp $CertPath/$DOMAIN/*.pem $PATH
    echo -e " ${YELLO}安装成功${PLAIN}"
}

AutoRenew() {
    echo -e " ${BLUE}因CertBot会自动设置续期, 故只设置自动复制新证书${PLAIN}"
    read -p " 请输入域名 (泛域名请输入xxxx.com) ：" DOMAIN
    read -p " 请输入安装路径：" PATH
    sed -i '$a\0 */12 * * * rm -rf $PATH/*.pem && cp $CertPath/$DOMAIN/*.pem $PATH' $CRON
    echo -e " ${YELLO}设置完成, 请重启使用证书的服务${PLAIN}"
}

Editor() {
    read -p " 请输入CloudFlare邮箱: " MAIL
    read -p " 请输入CloudFlare Global api：" KEY
    cat > /etc/letsencrypt/cloudflare.ini << EOF
dns_cloudflare_email = $MAIL
dns_cloudflare_api_key = $KEY
EOF
    echo -e " ${YELLO}修改成功${PLAIN}"
}

menu() {
	clear
	echo "######################################"
	echo -e "#         ${RED}CertBot一键脚本${PLAIN}          #"
	echo -e "#    ${GREEN}作者${PLAIN}: 怠惰(Slotheve)            #"
	echo -e "#    ${GREEN}网址${PLAIN}: https://slotheve.com      #"
	echo -e "#    ${GREEN}TG群${PLAIN}: https://t.me/slotheve     #"
	echo "######################################"
	echo " -------------"
	echo -e "  ${GREEN}1.${PLAIN}  安装CertBot"
	echo -e "  ${GREEN}2.${PLAIN}  申请证书"
	echo -e "  ${GREEN}3.${PLAIN}  安装证书"
	echo -e "  ${GREEN}4.${PLAIN}  设置自动续期"
	echo -e "  ${GREEN}5.${PLAIN}  修改API信息"
	echo " -------------"
	echo -e "  ${GREEN}0.${PLAIN}  退出"
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
			ApplyCert
			;;
		3)
			CopyCert
			;;
		4)
			AutoRenew
			;;
		5)
			Editor
			;;
		*)
			colorEcho $RED " 请选择正确的操作！"
			exit 1
			;;
	esac
}

check_sys
menu
