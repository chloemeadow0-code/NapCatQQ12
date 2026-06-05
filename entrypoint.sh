#!/bin/bash

# ============================================================
# NapCatQQ Entrypoint
# Every container start: set env, fix MAC, write configs, then start QQ.
# ============================================================

set -e

# ----------------------------------------------------------
# 1. Force-set environment variables
# ----------------------------------------------------------
export ACCOUNT=3022644106
export WEBUI_TOKEN=silas

# ----------------------------------------------------------
# 2. Fixed MAC address (critical: QQ uses MAC to identify
#    the device; a changed MAC triggers re-login / re-scan)
# ----------------------------------------------------------
MAC_ADDRESS="02:42:ac:11:00:69"

if command -v ip &>/dev/null; then
    ip link set eth0 down 2>/dev/null || true
    ip link set eth0 address "$MAC_ADDRESS" 2>/dev/null || true
    ip link set eth0 up 2>/dev/null || true
elif command -v ifconfig &>/dev/null; then
    ifconfig eth0 down 2>/dev/null || true
    ifconfig eth0 hw ether "$MAC_ADDRESS" 2>/dev/null || true
    ifconfig eth0 up 2>/dev/null || true
else
    # Last resort: spoof the MAC via /sys so QQ reads a consistent value
    mkdir -p /sys/class/net/eth0 2>/dev/null || true
    echo "$MAC_ADDRESS" > /sys/class/net/eth0/address 2>/dev/null || true
fi

echo "[entrypoint] MAC address set to $MAC_ADDRESS"

# ----------------------------------------------------------
# 3. Force-overwrite config files (every container start)
# ----------------------------------------------------------
mkdir -p /app/napcat/config

cat > /app/napcat/config/webui.json << 'EOF'
{
    "host": "0.0.0.0",
    "prefix": "",
    "port": 6099,
    "token": "silas",
    "loginRate": 3
}
EOF

cat > /app/napcat/config/onebot11.json << 'EOF'
{
  "network": {
    "httpServers": [],
    "httpSseServers": [],
    "httpClients": [],
    "websocketServers": [],
    "websocketClients": [
      {
        "enable": true,
        "name": "silas-ws",
        "url": "wss://silas.zeabur.app/qq-ws",
        "reportSelfMessage": false,
        "messagePostFormat": "array",
        "token": "",
        "debug": false,
        "heartInterval": 30000,
        "reconnectInterval": 30000
      }
    ],
    "plugins": []
  },
  "musicSignUrl": "",
  "enableLocalFile2Url": false,
  "parseMultMsg": false
}
EOF

echo "[entrypoint] webui.json & onebot11.json written."

# ----------------------------------------------------------
# 4. Start NapCat / QQ (delegate to original entrypoint)
# ----------------------------------------------------------
cd /app/napcat
if [ -f /app/entrypoint-original.sh ]; then
    exec bash /app/entrypoint-original.sh "$@"
else
    exec "$@"
fi
