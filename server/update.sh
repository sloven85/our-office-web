#!/usr/bin/env bash
# 게임을 배포하면(GitHub Pages) 서버도 저절로 따라간다.
# index.html 의 빌드 번호(OFFICE_BUILD)가 바뀌었으면 index.pck 를 새로 받아 서버를 다시 켠다.
set -eu
BASE="https://sloven85.github.io/our-office-web"
cd /opt/office
NEW="$(curl -fsSL "$BASE/index.html?t=$(date +%s)" \
	| sed -n "s/^const OFFICE_BUILD = '\(.*\)';\$/\1/p" | head -1)"
if [ -z "$NEW" ] || [ "$NEW" = "dev" ]; then
	exit 0
fi
OLD="$(cat build.txt 2>/dev/null || true)"
if [ "$NEW" = "$OLD" ] && [ -s index.pck ]; then
	exit 0
fi
echo "새 빌드 $NEW (지금 ${OLD:-없음}) — 받는 중"
curl -fsSL -o index.pck.new "$BASE/index.pck?v=$NEW"
test -s index.pck.new
chown office:office index.pck.new
mv index.pck.new index.pck
echo "$NEW" > build.txt
systemctl restart office-server
echo "서버를 $NEW 로 다시 켰습니다"
