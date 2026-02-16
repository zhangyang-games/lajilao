#!/bin/bash

# ==================================================
# 垃圾佬捡破烂：弱鸡三千安装脚本 (Trash-3000)
# 版本：v1.2 (自动快捷键版)
# 整合内容：Hysteria2 (IPv6/双栈) | VLESS-Reality | Serv00保号
# ==================================================

# --- 全局颜色定义 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# --- 核心功能：自动创建快捷指令 ---
# 这一步是为了让你那句 "输入 lajilao 调出脚本" 变成真的！
create_shortcut() {
    # 区分 Root 用户 (VPS) 和 普通用户 (Serv00)
    if [[ $EUID -eq 0 ]]; then
        #如果是 Root，安装到 /usr/bin/lajilao
        if [ -f /usr/bin/lajilao ]; then return; fi
        cat > /usr/bin/lajilao << EOF
#!/bin/bash
bash <(curl -Ls https://raw.githubusercontent.com/zhangyang-games/lajilao/refs/heads/main/lajilao.sh)
EOF
        chmod +x /usr/bin/lajilao
        echo -e "${GREEN}检测到首次运行，已自动设置快捷指令！${PLAIN}"
        echo -e "${GREEN}以后直接输入 ${YELLOW}lajilao${GREEN} 即可唤醒本脚本。${PLAIN}"
        sleep 2
    else
        #如果是 Serv00 或非 Root，安装到 ~/bin/lajilao
        mkdir -p ~/bin
        if [ -f ~/bin/lajilao ]; then return; fi
        cat > ~/bin/lajilao << EOF
#!/bin/bash
bash <(curl -Ls https://raw.githubusercontent.com/zhangyang-games/lajilao/refs/heads/main/lajilao.sh)
EOF
        chmod +x ~/bin/lajilao
        export PATH=$HOME/bin:$PATH
        echo -e "${GREEN}检测到首次运行 (非Root环境)，已设置快捷指令！${PLAIN}"
        echo -e "${GREEN}以后输入 ${YELLOW}lajilao${GREEN} 即可唤醒 (需重新登录生效)。${PLAIN}"
        sleep 2
    fi
}

# --- 辅助函数 ---

# 打印表头
print_header() {
    clear
    echo -e "${YELLOW}"
    cat << "EOF"
   ██╗      █████╗      ██╗██╗    ██╗    ██╗██╗      █████╗  ██████╗ 
   ██║     ██╔══██╗     ██║██║    ██║    ██║██║     ██╔══██╗██╔═══██╗
   ██║     ███████║     ██║██║    ██║    ██║██║     ███████║██║   ██║
   ██║     ██╔══██║██   ██║██║    ██║    ██║██║     ██╔══██║██║   ██║
   ███████╗██║  ██║╚█████╔╝██║    ██║    ██║███████╗██║  ██║╚██████╔╝
   ╚══════╝╚═╝  ╚═╝ ╚════╝ ╚═╝    ╚═╝    ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ 
EOF
    echo -e "${PLAIN}"
    
    echo -e "${RED}===================================================================================================${PLAIN}"
    echo -e "${GREEN}           🗑️  垃圾佬捡破烂：弱鸡三千安装脚本 (Trash-3000)  v1.2${PLAIN}"
    echo -e "${RED}===================================================================================================${PLAIN}"
    echo -e "${YELLOW}  👉 本脚本适用于 各种弱鸡 VPS 常用项目部署${PLAIN}"
    echo -e "${YELLOW}  👉 本脚本是小白学习的总结，不做任何商业用途和盈利${PLAIN}"
    echo -e "${YELLOW}  🙏 感谢 Gemini 地球之神的全局帮助${PLAIN}"
    echo -e "${RED}===================================================================================================${PLAIN}"
    echo ""
    echo -e "  1. 🐔 纯 IPv6 专用：Hysteria 2 (适合 EuServ/Hax 等)"
    echo -e "  2. 🐔 双栈/标准鸡：Hysteria 2 (适合 CloudCone/RackNerd 等)"
    echo -e "  3. 👻 VLESS-Reality/Vision (通用最强防封)"
    echo -e "  4. 🐸 Serv00 专用：部署 Rclone 备份 & 自动保号"
    echo -e "${RED}  0. 🏃 跑路 (退出脚本)${PLAIN}"
    echo -e ""
    echo -e "${BLUE}当前系统信息: $(uname -s) $(uname -r)${PLAIN}"
    echo ""
}

# 检查 Root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[错误] 必须要 root 用户才能运行此功能！${PLAIN}"
        echo -e "请尝试输入: ${YELLOW}sudo -i${PLAIN} 切换用户后再试。"
        return 1
    fi
    return 0
}

# 域名输入检查
get_domain() {
    local prompt_text="$1"
    while true; do
        echo -e "${YELLOW}$prompt_text${PLAIN}"
        read -p "域名: " USER_DOMAIN
        if [ -z "$USER_DOMAIN" ]; then
            echo -e "${RED}域名不能为空，老板输一个吧...${PLAIN}"
        else
            return 0
        fi
    done
}

# --- 功能模块 1: 纯 IPv6 Hysteria 2 ---
install_hy2_ipv6() {
    check_root || return
    echo -e "${GREEN}>>> 启动：纯 IPv6 Hysteria 2 安装程序...${PLAIN}"
    
    get_domain "请输入已解析 AAAA 记录的域名 (千万不要有 A 记录！):"
    local EMAIL="admin@${USER_DOMAIN}"

    echo -e "${GREEN}1. 暴力清理 IPv6 防火墙 (专治 EuServ 不服)...${PLAIN}"
    ip6tables -P INPUT ACCEPT
    ip6tables -P FORWARD ACCEPT
    ip6tables -P OUTPUT ACCEPT
    ip6tables -F
    
    echo -e "${GREEN}2. 安装基础工具...${PLAIN}"
    apt update -y
    apt install curl wget socat cron systemd-timesyncd -y || { echo -e "${RED}apt 安装失败${PLAIN}"; return; }

    echo -e "${GREEN}3. 申请证书 (Let's Encrypt IPv6)...${PLAIN}"
    curl https://get.acme.sh | sh
    source ~/.bashrc
    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    ~/.acme.sh/acme.sh --register-account -m "${EMAIL}"
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    ~/.acme.sh/acme.sh --issue -d "${USER_DOMAIN}" --standalone --listen-v6 --force

    if [ $? -ne 0 ]; then
        echo -e "${RED}[失败] 证书申请挂了。请检查你的域名只有 AAAA 记录，且没有开启 Cloudflare 小黄云。${PLAIN}"
        return
    fi

    echo -e "${GREEN}4. 安装 Hysteria 2...${PLAIN}"
    bash <(curl -fsSL https://get.hy2.sh/)

    mkdir -p /etc/hysteria
    ~/.acme.sh/acme.sh --installcert -d "${USER_DOMAIN}" \
        --key-file /etc/hysteria/server.key \
        --fullchain-file /etc/hysteria/server.crt \
        --ecc

    local PASSWORD=$(date +%s%N | md5sum | head -c 16)
    
    cat <<EOF > /etc/hysteria/config.yaml
listen: :443
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key
auth:
  type: password
  password: "${PASSWORD}"
masquerade:
  type: proxy
  proxy:
    url: https://bing.com/
    rewriteHost: true
EOF

    chown -R hysteria:hysteria /etc/hysteria
    chmod 644 /etc/hysteria/server.crt
    chmod 600 /etc/hysteria/server.key
    systemctl enable hysteria-server.service
    systemctl restart hysteria-server.service

    echo -e "\n${GREEN}✅ 安装完成！(纯 IPv6 版)${PLAIN}"
    echo -e "链接: hysteria2://${PASSWORD}@[${USER_DOMAIN}]:443?peer=${USER_DOMAIN}&insecure=0&obfs=none#MyHv6"
    read -p "按回车返回主菜单..."
}

# --- 功能模块 2: 双栈/标准 Hysteria 2 ---
install_hy2_std() {
    check_root || return
    echo -e "${GREEN}>>> 启动：标准版 Hysteria 2 安装程序...${PLAIN}"
    
    get_domain "请输入解析到本机 IP 的域名:"
    local EMAIL="admin@${USER_DOMAIN}"

    echo -e "${GREEN}1. 环境准备...${PLAIN}"
    timedatectl set-ntp true
    if [ -x "$(command -v apt-get)" ]; then
        apt update -y && apt install curl wget socat cron -y
    elif [ -x "$(command -v yum)" ]; then
        yum update -y && yum install curl wget socat cronie -y
    fi

    systemctl stop nginx >/dev/null 2>&1
    systemctl stop apache2 >/dev/null 2>&1

    echo -e "${GREEN}2. 申请证书...${PLAIN}"
    curl https://get.acme.sh | sh
    source ~/.bashrc
    ~/.acme.sh/acme.sh --register-account -m "${EMAIL}"
    ~/.acme.sh/acme.sh --issue -d "${USER_DOMAIN}" --standalone --force

    if [ $? -ne 0 ]; then
        echo -e "${RED}[失败] 证书申请失败。请检查域名解析和80端口占用。${PLAIN}"
        return
    fi

    echo -e "${GREEN}3. 安装与配置 Hysteria 2...${PLAIN}"
    bash <(curl -fsSL https://get.hy2.sh/)
    mkdir -p /etc/hysteria
    ~/.acme.sh/acme.sh --installcert -d "${USER_DOMAIN}" --key-file /etc/hysteria/server.key --fullchain-file /etc/hysteria/server.crt

    local PASSWORD=$(date +%s%N | md5sum | head -c 16)
    
    cat <<EOF > /etc/hysteria/config.yaml
listen: :443
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key
auth:
  type: password
  password: "${PASSWORD}"
masquerade:
  type: proxy
  proxy:
    url: https://bing.com/
    rewriteHost: true
quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
EOF

    chown -R hysteria:hysteria /etc/hysteria
    chmod 644 /etc/hysteria/server.crt
    chmod 600 /etc/hysteria/server.key
    if command -v ufw >/dev/null; then ufw allow 80; ufw allow 443; ufw reload; fi
    systemctl enable hysteria-server.service
    systemctl restart hysteria-server.service

    echo -e "\n${GREEN}✅ 安装完成！(双栈标准版)${PLAIN}"
    echo -e "链接: hysteria2://${PASSWORD}@${USER_DOMAIN}:443?peer=${USER_DOMAIN}&insecure=0&obfs=none#MyHysteria2"
    read -p "按回车返回主菜单..."
}

# --- 功能模块 3: VLESS-Reality/Vision ---
install_vless() {
    check_root || return
    echo -e "${GREEN}>>> 启动：Xray VLESS 管理脚本...${PLAIN}"
    
    if [ -f /etc/debian_version ]; then
        apt-get update -y && apt-get install -y curl openssl jq socat
    elif [ -f /etc/redhat-release ]; then
        yum update -y && yum install -y curl openssl socat jq
    fi

    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

    echo -e "${YELLOW}请选择模式：${PLAIN}"
    echo "1. VLESS-Reality (无域名)"
    echo "2. VLESS-Vision-TLS (有域名)"
    read -p "选择 [1-2]: " MODE

    local UUID=$(xray uuid)
    local PORT=443
    local CONFIG_FILE="/usr/local/etc/xray/config.json"

    if [ "$MODE" == "2" ]; then
        get_domain "请输入你的域名:"
        curl https://get.acme.sh | sh
        ~/.acme.sh/acme.sh --issue -d "${USER_DOMAIN}" --standalone --force
        mkdir -p /usr/local/etc/xray/cert
        ~/.acme.sh/acme.sh --installcert -d "${USER_DOMAIN}" --fullchainpath "/usr/local/etc/xray/cert/fullchain.pem" --keypath "/usr/local/etc/xray/cert/privkey.pem" --ecc
        
        cat > "$CONFIG_FILE" << EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [{
    "port": $PORT, "protocol": "vless",
    "settings": { "clients": [{ "id": "$UUID", "flow": "xtls-rprx-vision" }], "decryption": "none" },
    "streamSettings": { "network": "tcp", "security": "tls", "tlsSettings": { "certificates": [{ "certificateFile": "/usr/local/etc/xray/cert/fullchain.pem", "keyFile": "/usr/local/etc/xray/cert/privkey.pem" }] } },
    "sniffing": { "enabled": true, "destOverride": ["http", "tls"] }
  }],
  "outbounds": [{ "protocol": "freedom", "tag": "direct" }]
}
EOF
    else
        local KEYS=$(xray x25519)
        local PK=$(echo "$KEYS" | awk '/Private/{print $3}')
        local PUB=$(echo "$KEYS" | awk '/Public/{print $3}')
        local DEST="www.microsoft.com:443"
        local SNI="www.microsoft.com"
        local SHORT_ID=$(openssl rand -hex 8)

        cat > "$CONFIG_FILE" << EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [{
    "port": $PORT, "protocol": "vless",
    "settings": { "clients": [{ "id": "$UUID", "flow": "xtls-rprx-vision" }], "decryption": "none" },
    "streamSettings": {
      "network": "tcp", "security": "reality",
      "realitySettings": { "show": false, "dest": "$DEST", "xver": 0, "serverNames": ["$SNI"], "privateKey": "$PK", "shortIds": ["", "$SHORT_ID"] }
    },
    "sniffing": { "enabled": true, "destOverride": ["http", "tls"] }
  }],
  "outbounds": [{ "protocol": "freedom", "tag": "direct" }]
}
EOF
        local IP=$(curl -s4 ifconfig.me)
        [ -z "$IP" ] && IP=$(curl -s6 ifconfig.me)
        echo -e "${YELLOW}链接: vless://$UUID@$IP:$PORT?security=reality&encryption=none&type=tcp&flow=xtls-rprx-vision&sni=$SNI&fp=chrome&pbk=$PUB&sid=$SHORT_ID#Reality-Node${PLAIN}"
    fi

    systemctl restart xray
    systemctl enable xray
    read -p "按回车返回主菜单..."
}

# --- 功能模块 4: Serv00 专用 ---
setup_serv00() {
    if [[ "$(uname -s)" != "FreeBSD" ]]; then
        echo -e "${RED}[警告] 你的系统是 $(uname -s)，不是 FreeBSD！${PLAIN}"
        echo -e "Serv00 脚本包含 FreeBSD 专用二进制文件，在 Linux 上无法运行。"
        echo -e "你确定要强行继续吗？(y/n)"
        read -p "选择: " choice
        if [[ "$choice" != "y" ]]; then return; fi
    fi

    echo -e "${BLUE}>>> 启动：Serv00 自动化部署 (Rclone + 自动备份)...${PLAIN}"
    mkdir -p ~/bin ~/tmp ~/scripts
    export PATH=$HOME/bin:$PATH
    [[ ":$PATH:" != *":$HOME/bin:"* ]] && echo 'export PATH=$HOME/bin:$PATH' >> ~/.profile

    if ! command -v rclone >/dev/null 2>&1; then
        echo "⬇️  正在下载 FreeBSD 版 Rclone..."
        fetch -q -o - https://downloads.rclone.org/rclone-current-freebsd-amd64.zip | unzip -q -d ~/tmp -
        mv ~/tmp/rclone-*-freebsd-amd64/rclone ~/bin/
        chmod +x ~/bin/rclone
        rm -rf ~/tmp/rclone-*
    fi

    cat << 'EOF' > ~/scripts/daily_backup.sh
#!/bin/sh
export PATH=$HOME/bin:$PATH
REMOTE="dropbox:VPS/Serv00_FreeBSD"
BACKUP_NAME="Serv00_$(date +%Y%m%d).tar.gz"
TMP_FILE="$HOME/tmp/$BACKUP_NAME"

echo "[$(date)] 📦 打包中..."
tar -czf "$TMP_FILE" -C "$HOME" domains
echo "[$(date)] ☁️ 上传中..."
rclone copy "$TMP_FILE" "$REMOTE" --transfers 1 --checkers 1 --tpslimit 1
rclone delete "$REMOTE" --min-age 7d --checkers 1
rm -f "$TMP_FILE"
echo "[$(date)] ✅ 完成!"
EOF
    chmod +x ~/scripts/daily_backup.sh

    echo '#!/bin/sh' > ~/bin/poke
    echo '~/scripts/daily_backup.sh' >> ~/bin/poke
    chmod +x ~/bin/poke

    (crontab -l 2>/dev/null | grep -v "daily_backup.sh"; echo "0 22 * * * sleep \$(jot -r 1 0 3600) && /bin/sh $HOME/scripts/daily_backup.sh") | crontab -

    echo -e "${GREEN}🎉 Serv00 部署成功！${PLAIN}"
    echo -e "请运行 ${YELLOW}rclone config${PLAIN} 绑定网盘，然后输入 ${YELLOW}poke${PLAIN} 测试备份。"
    read -p "按回车返回主菜单..."
}

# --- 脚本入口 ---

# 1. 优先尝试创建快捷键
create_shortcut

# 2. 进入主循环
while true; do
    print_header
    read -p "请选择一项 (输入数字): " CHOICE
    case "$CHOICE" in
        1) install_hy2_ipv6 ;;
        2) install_hy2_std ;;
        3) install_vless ;;
        4) setup_serv00 ;;
        0) 
            # 这里就是你要修改的退出语！
            echo -e "${GREEN}👋 再见垃圾佬！再次输入：${YELLOW}lajilao${GREEN} 可以调出本脚本${PLAIN}"
            exit 0 
            ;;
        *) echo -e "${RED}输入错误，请输入 0-4 之间的数字${PLAIN}"; sleep 1 ;;
    esac
done
