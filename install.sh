#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-8082}"
WORKERS="${WORKERS:-2}"
FQDN="${FQDN:-}"
INSTALL_DIR="/opt/MTProxy"
SECRET_FILE="/etc/mtproxy.secret"
SERVICE_FILE="/etc/systemd/system/mtproxy.service"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root."
  exit 1
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y   git curl build-essential libssl-dev zlib1g-dev

if [[ -d "${INSTALL_DIR}/.git" ]]; then
  git -C "${INSTALL_DIR}" pull --ff-only
else
  rm -rf "${INSTALL_DIR}"
  git clone https://github.com/TelegramMessenger/MTProxy.git "${INSTALL_DIR}"
fi

cd "${INSTALL_DIR}"
make -j"$(nproc)"

curl -4 --http1.1 --retry 10 --retry-delay 2 --retry-all-errors -fL   https://core.telegram.org/getProxySecret -o proxy-secret

curl -4 --http1.1 --retry 10 --retry-delay 2 --retry-all-errors -fL   https://core.telegram.org/getProxyConfig -o proxy-multi.conf

if [[ ! -s "${SECRET_FILE}" ]]; then
  openssl rand -hex 16 > "${SECRET_FILE}"
  chmod 600 "${SECRET_FILE}"
fi

SECRET="$(cat "${SECRET_FILE}")"

cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=Telegram MTProxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/objs/bin/mtproto-proxy -u nobody -p 8888 -H ${PORT} -S ${SECRET} --aes-pwd ${INSTALL_DIR}/proxy-secret ${INSTALL_DIR}/proxy-multi.conf -M ${WORKERS}
Restart=always
RestartSec=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now mtproxy

if command -v ufw >/dev/null 2>&1 && ufw status | grep -q '^Status: active'; then
  ufw allow "${PORT}/tcp"
fi

PUBLIC_IP="$(curl -4 -fsSL https://api.ipify.org || true)"
SERVER="${FQDN:-$PUBLIC_IP}"

echo
echo "MTProxy installed."
echo "Server : $SERVER"
echo "Port   : $PORT"
echo "Secret : $SECRET"
echo "Link   : tg://proxy?server=${SERVER}&port=${PORT}&secret=${SECRET}"
echo
systemctl --no-pager --full status mtproxy || true
