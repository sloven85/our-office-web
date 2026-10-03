#!/usr/bin/env bash
# 사무실 서버 VM 을 꾸린다. VM 이 켜질 때마다 돈다(시작 스크립트) — 여러 번 돌려도 된다.
#   Godot 4.3 (화면 없는 리눅스판) · Caddy(wss 보안 연결) · systemd 서비스 · 자동 업데이트
set -eu
BASE="https://sloven85.github.io/our-office-web"
GODOT_URL="https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip"
export DEBIAN_FRONTEND=noninteractive

# 이 VM 의 바깥 IP → 주소 (34.64.1.2 → 34-64-1-2.sslip.io)
IP="$(curl -fsS -H 'Metadata-Flavor: Google' \
	http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)"
HOST="${IP//./-}.sslip.io"

# 메모리가 1GB 뿐이라 여유 공간(swap)을 1GB 붙인다
if [ ! -f /swapfile ]; then
	fallocate -l 1G /swapfile && chmod 600 /swapfile && mkswap /swapfile
	echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi
swapon /swapfile 2>/dev/null || true

# libfontconfig1 — 없으면 Godot 이 켤 때마다 "Unable to load fontconfig" 를 줄줄이 찍는다 (해는 없다)
if ! command -v caddy >/dev/null || ! command -v unzip >/dev/null || ! ldconfig -p | grep -q libfontconfig.so.1; then
	apt-get update -q
	apt-get install -yq curl unzip gnupg debian-keyring debian-archive-keyring apt-transport-https libfontconfig1
	curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
		| gpg --batch --yes --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
	curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
		> /etc/apt/sources.list.d/caddy-stable.list
	apt-get update -q
	apt-get install -yq caddy
fi

id office >/dev/null 2>&1 || useradd --system --create-home --home-dir /opt/office --shell /usr/sbin/nologin office
mkdir -p /opt/office
cd /opt/office
if [ ! -x godot ]; then
	curl -fsSL -o godot.zip "$GODOT_URL"
	unzip -oq godot.zip
	mv Godot_v4.3-stable_linux.x86_64 godot
	rm -f godot.zip
	chmod +x godot
fi

# 서버 파일은 게임과 같이 배포된다 (워크플로가 server/ 를 웹 빌드 옆에 올린다) — 매번 새것으로
for f in office-server.service office-update.service office-update.timer Caddyfile update.sh; do
	curl -fsSL -o "$f" "$BASE/server/$f?t=$(date +%s)"
done
chmod +x update.sh
sed "s/__HOST__/$HOST/" Caddyfile > /etc/caddy/Caddyfile
cp office-server.service office-update.service office-update.timer /etc/systemd/system/
chown -R office:office /opt/office

systemctl daemon-reload
systemctl enable office-server office-update.timer caddy >/dev/null
./update.sh || true              # 게임 빌드를 받는다 (받았으면 서버를 켠다)
systemctl start office-server office-update.timer
systemctl reload caddy || systemctl restart caddy

echo
echo "사무실 서버 주소:  wss://$HOST"
