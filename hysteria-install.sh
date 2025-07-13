#!/bin/bash

set -e

echo "[+] Updating system..."
apt update && apt upgrade -y
apt install curl wget tar openssl -y

echo "[+] Creating folders..."
mkdir -p /opt/hysteria /etc/hysteria
cd /opt/hysteria

echo "[+] Downloading Hysteria binary..."
wget -q https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64 -O hysteria
chmod +x hysteria
mv hysteria /usr/local/bin/

echo "[+] Generating self-signed TLS cert..."
openssl req -x509 -newkey rsa:2048 -days 365 -nodes \
-keyout /etc/hysteria/hysteria.key \
-out /etc/hysteria/hysteria.crt \
-subj "/CN=Hysteria VPN"

echo "[+] Creating config file..."
cat > /etc/hysteria/config.yaml <<EOF
listen: :5678

tls:
  cert: /etc/hysteria/hysteria.crt
  key: /etc/hysteria/hysteria.key

auth:
  type: password
  password: yourStrongPassword123

obfs:
  type: salamander
  password: salamander123


masquerade:
  type: proxy
  proxy:
    url: https://www.cloudflare.com

disable_udp: false
EOF

echo "[+] Creating systemd service..."
cat > /etc/systemd/system/hysteria-server.service <<EOF
[Unit]
Description=Hysteria VPN Server
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "[+] Enabling and starting service..."
systemctl daemon-reexec
systemctl enable --now hysteria-server

echo "[+] Allowing UDP port 5678..."
ufw allow 5678/udp || true
iptables -A INPUT -p udp --dport 5678 -j ACCEPT || true

echo "[✅] Hysteria VPN server installed and running on UDP port 5678"
