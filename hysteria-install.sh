#!/bin/bash

set -e

echo "[+] Installing Hysteria2 with Obfuscation..."

# Update system
apt update && apt upgrade -y
apt install curl wget tar openssl -y

# Create folders
mkdir -p /opt/hysteria /etc/hysteria
cd /opt/hysteria

# Download latest Hysteria binary
wget -q https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64 -O hysteria
chmod +x hysteria
mv hysteria /usr/local/bin/

# Generate self-signed TLS certificate
openssl req -x509 -newkey rsa:2048 -days 365 -nodes \
  -keyout /etc/hysteria/hysteria.key \
  -out /etc/hysteria/hysteria.crt \
  -subj "/CN=HysteriaVPN"

# Create server config file
cat > /etc/hysteria/config.yaml <<EOF
listen: :5353

tls:
  cert: /etc/hysteria/hysteria.crt
  key: /etc/hysteria/hysteria.key

auth:
  type: password
  password: yourStrongPassword123

obfs:
  type: salamander
  password: test123

masquerade:
  type: proxy
  proxy:
    url: https://www.cloudflare.com

disable_udp: false
EOF

# Create systemd service
cat > /etc/systemd/system/hysteria-server.service <<EOF
[Unit]
Description=Hysteria2 VPN Server with Obfuscation
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload, enable and start the service
systemctl daemon-reexec
systemctl enable --now hysteria-server

# Open firewall
ufw allow 5353/udp || true
iptables -A INPUT -p udp --dport 5678 -j ACCEPT || true

echo "[✅] Hysteria2 server installed and running on UDP port 5353 with Obfuscation"
echo "[🔑] Connection Link (for HTTP Custom):"
echo ""
echo "hysteria2://IronWallPass947@@YOUR_SERVER_IP:5678/?insecure=1&obfs=test123&upmbps=10&downmbps=100"
