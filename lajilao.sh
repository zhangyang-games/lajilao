#!/bin/bash

# ==================================================
# 3-in-1 融合工具箱 v3.1 (智能 CPU 架构识别版)
# Author: Gemini (For Zhang Caiduo)
# System: Ubuntu 22.04+ (x86_64 / ARM64)
# ==================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PLAIN='\033[0m'

# 检查 Root
[[ $EUID -ne 0 ]] && echo -e "${RED}错误：必须使用 root 用户运行此脚本！${PLAIN}" && exit 1

install_base() {
    echo -e "${YELLOW}正在检查并安装必要组件...${PLAIN}"
    apt update -y
    apt install -y curl wget tar socat jq git qrencode
}

# ================= 1. TUIC 安装 (自动识别架构) =================
check_domain_validity() {
    if [[ "$1" == *" "* ]] || [ -z "$1" ]; then return 1; fi
    return 0
}

install_tuic() {
    echo -e "${GREEN}>>> 开始安装/修复 TUIC v5...${PLAIN}"
    
    # 域名处理
    while true; do
        if [ -f "/etc/tuic/domain_name" ]; then
            default_domain=$(cat /etc/tuic/domain_name)
            if [[ "$default_domain" == *" "* ]]; then default_domain=""; fi
        fi
        if [ -n "$default_domain" ]; then
            read -p "请输入你的域名 (回车默认: ${default_domain}): " domain
            domain=${domain:-$default_domain}
        else
            read -p "请输入你的域名 (例如 cc-v5.xccop.eu.org): " domain
        fi
        if check_domain_validity "$domain"; then break; else echo -e "${RED}错误：域名不能包含空格！${PLAIN}"; rm -f /etc/tuic/domain_name; fi
    done
    mkdir -p /etc/tuic
    echo "$domain" > /etc/tuic/domain_name

    # 证书处理
    if [ -f "/etc/tuic/fullchain.pem" ] && [ -f "/etc/tuic/privkey.pem" ]; then
        echo -e "${GREEN}检测到证书文件已存在，跳过申请步骤！${PLAIN}"
    else
        echo -e "${YELLOW}证书未找到，开始申请证书...${PLAIN}"
        curl https://get.acme.sh | sh
        systemctl stop nginx 2>/dev/null
        systemctl stop apache2 2>/dev/null
        ~/.acme.sh/acme.sh --register-account -m admin@${domain}
        ~/.acme.sh/acme.sh --issue -d ${domain} --standalone --force
        if [ $? -ne 0 ]; then echo -e "${RED}证书申请失败！请检查 80 端口。${PLAIN}"; return; fi
        ~/.acme.sh/acme.sh --install-cert -d ${domain} --key-file /etc/tuic/privkey.pem --fullchain-file /etc/tuic/fullchain.pem
    fi

    # 下载核心 (智能识别架构)
    arch=$(uname -m)
    echo -e "${YELLOW}检测到系统架构: ${arch}${PLAIN}"
    
    if [[ "$arch" == "x86_64" ]]; then
        download_url="https://github.com/tuic-protocol/tuic/releases/download/tuic-server-1.0.0/tuic-server-1.0.0-x86_64-unknown-linux-gnu"
    elif [[ "$arch" == "aarch64" ]]; then
        download_url="https://github.com/tuic-protocol/tuic/releases/download/tuic-server-1.0.0/tuic-server-1.0.0-aarch64-unknown-linux-gnu"
    else
        echo -e "${RED}不支持的架构: ${arch}${PLAIN}"; return
    fi

    echo -e "${YELLOW}正在下载 TUIC Core v1.0.0...${PLAIN}"
    rm -f /usr/local/bin/tuic-server
    wget -O /usr/local/bin/tuic-server "$download_url"
    chmod +x /usr/local/bin/tuic-server

    # 配置
    read -p "请输入 TUIC 端口 (回车默认 8443): " tuic_port
    tuic_port=${tuic_port:-8443}
    tuic_uuid=$(cat /proc/sys/kernel/random/uuid)
    read -p "请输入 UUID (回车默认随机): " input_uuid
    tuic_uuid=${input_uuid:-$tuic_uuid}
    read -p "请输入密码 (回车默认 admin): " tuic_pass
    tuic_pass=${tuic_pass:-admin}

    cat > /etc/tuic/config.json <<EOF
{
    "server": "0.0.0.0:${tuic_port}",
    "users": {"${tuic_uuid}": "${tuic_pass}"},
    "certificate": "/etc/tuic/fullchain.pem",
    "private_key": "/etc/tuic/privkey.pem",
    "congestion_control": "bbr",
    "alpn": ["h3", "spdy/3.1"],
    "log_level": "info"
}
EOF
    cat > /etc/systemd/system/tuic.service <<EOF
[Unit]
Description=TUIC Server
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/tuic-server -c /etc/tuic/config.json
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable tuic; systemctl restart tuic
    echo -e "\n${GREEN}TUIC 安装并启动完成！${PLAIN}"
    show_tuic_info
}

# ================= 2. WireGuard 安装 =================
install_wireguard() {
    echo -e "${GREEN}>>> 正在调用 Angristan WireGuard 脚本...${PLAIN}"
    curl -O https://raw.githubusercontent.com/angristan/wireguard-install/master/wireguard-install.sh
    chmod +x wireguard-install.sh
    ./wireguard-install.sh
    echo -e "${GREEN}WireGuard 设置结束！${PLAIN}"
    show_wg_info
}

# ================= 3. BBR =================
enable_bbr() {
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    echo -e "${GREEN}BBR 已开启！${PLAIN}"
}

# ================= 辅助: 查找并显示 WG 配置 =================
show_wg_info() {
    # 兼容 Oracle 默认用户路径
    wg_conf=$(find /root /home/ubuntu -maxdepth 1 -name "wg0-client-*.conf" 2>/dev/null | head -n 1)

    if [ -z "$wg_conf" ]; then
        echo -e "${YELLOW}提示：未找到自动生成的 WireGuard 客户端文件。${PLAIN}"
    else
        echo -e "\n${SKYBLUE}============== WireGuard 配置 (${wg_conf}) ==============${PLAIN}"
        cat "$wg_conf"
        echo -e "--------------------------------------------"
        qrencode -t ansiutf8 < "$wg_conf"
        echo -e "${SKYBLUE}=========================================================${PLAIN}\n"
    fi
}

# ================= 4. 查看/修正 =================
fix_domain() {
    echo -e "${YELLOW}当前域名: $(cat /etc/tuic/domain_name 2>/dev/null)${PLAIN}"
    while true; do
        read -p "请输入正确的域名: " new_domain
        if check_domain_validity "$new_domain"; then
            echo "$new_domain" > /etc/tuic/domain_name
            echo -e "${GREEN}域名已修正!${PLAIN}"; show_tuic_info; break
        else
             echo -e "${RED}域名不能包含空格！${PLAIN}"
        fi
    done
}

show_tuic_info() {
    if [ ! -f "/etc/tuic/config.json" ]; then echo -e "${RED}未安装 TUIC${PLAIN}"; return; fi
    if [ -f "/etc/tuic/domain_name" ]; then domain=$(cat /etc/tuic/domain_name); else domain=$(curl -s ifconfig.me); fi
    if [[ "$domain" == *" "* ]]; then echo -e "${RED}域名格式错误，请按 5 修复!${PLAIN}"; return; fi

    port=$(jq -r '.server' /etc/tuic/config.json | cut -d: -f2)
    uuid=$(jq -r '.users | keys_unsorted[0]' /etc/tuic/config.json)
    pass=$(jq -r ".users[\"$uuid\"]" /etc/tuic/config.json)
    tuic_link="tuic://${uuid}:${pass}@${domain}:${port}/?congestion_control=bbr&alpn=h3&sni=${domain}&allow_insecure=1#TUIC_${domain}"

    echo -e "\n${SKYBLUE}============== TUIC 信息 ==============${PLAIN}"
    echo -e "地址: ${GREEN}${domain}${PLAIN}"
    echo -e "端口: ${GREEN}${port}${PLAIN}"
    echo -e "密码: ${GREEN}${pass}${PLAIN}"
    echo -e "-------------------------------------------"
    echo -e "${YELLOW}${tuic_link}${PLAIN}"
    echo -e "-------------------------------------------"
    qrencode -t ansiutf8 "${tuic_link}"
    echo -e "${SKYBLUE}=======================================${PLAIN}\n"
}

# ================= 主菜单 =================
clear
echo -e "========================================"
echo -e "    张财多 3-in-1 工具箱 v3.1 (智能架构版)"
echo -e "========================================"
echo -e "  1. 安装 TUIC v5 (自动识别 CPU)"
echo -e "  2. 安装 WireGuard"
echo -e "  3. 开启 BBR 加速"
echo -e "  ------------------------------------"
echo -e "  4. 查看 TUIC 配置"
echo -e "  5. 查看 WireGuard 配置 (已适配 Oracle)"
echo -e "  6. 修正 TUIC 域名"
echo -e "  ------------------------------------"
echo -e "  0. 退出"
echo -e "========================================"
read -p "请输入数字 [0-6]: " num

case "$num" in
    1) install_base; install_tuic ;;
    2) install_base; install_wireguard ;;
    3) enable_bbr ;;
    4) show_tuic_info ;;
    5) show_wg_info ;;
    6) fix_domain ;;
    0) exit 0 ;;
    *) echo -e "${RED}输入错误${PLAIN}" ;;
esac
