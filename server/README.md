# 사무실 서버 (구글 클라우드 · 서울)

> **지금은 쓰지 않습니다 (2026-10-01).** 기기마다 사무실을 따로 돌리고, 인테리어와 메신저만 같이 씁니다.
> 서버 한 대로 같이 돌리면 배속 · 장면 넘기기가 둘에게 같이 걸려서 바꿨습니다.
> VM · 고정 IP · 방화벽 규칙(office-web)은 2026-10-01 에 지웠습니다. 다시 쓰려면 아래 "만들기" 부터 다시 하고
> `godot/scripts/net/Net.gd` 의 `SERVER_URL` 을 채웁니다. 금고의 `GEMINI_KEY` 는 AI 중계소가 쓰니 지우지 않습니다.

사무실을 **서버 한 대가 24시간 맡아서** 돌립니다. 폰 · 태블릿 · 노트북은 모두 이 서버에 붙어
같은 사무실을 봅니다. 그래서 기기마다 저장이 갈리지 않고, 둘이 같은 순간의 직원들을 봅니다.
서버에 못 붙으면(꺼져 있거나 인터넷이 끊기면) 게임은 예전처럼 기기 혼자 돕니다.

- 서버는 이 게임을 **화면 없이** 돌립니다. 웹으로 배포되는 `index.pck` 를 그대로 받아 씁니다.
- 게임을 배포하면 서버가 5분 안에 새 빌드를 받아 다시 켜집니다 (`update.sh`).
- **아무도 접속하지 않으면 사무실 시간이 멈춥니다.** 누가 들어오면 다시 흐릅니다.
- 저장은 지금과 같은 Firestore 문서(`office/shared`)에 서버가 올립니다.
- AI 답장은 서버가 만듭니다. 키는 이미 있는 비밀 `GEMINI_KEY` 를 씁니다.
- **꾸미기(인테리어)는 한 사람씩** 합니다. [편집] 을 끄면 바뀐 배치가 서버로 갑니다. 그러면 서버와
  모든 기기가 몇 초 동안 새로 그려집니다. 이때 심부름 중이던 직원은 제자리로 돌아옵니다.

## 비용 (대략)

| 항목 | 한 달 |
| --- | --- |
| e2-micro VM (서울) | 약 7~8달러 |
| 고정 IP | 약 3.6달러 |
| 디스크 10GB | 약 0.5달러 |
| 나가는 통신 (한 기기에 초당 1KB 안팎) | 거의 0 |

합쳐서 **월 12달러(약 1만 6천 원) 안팎**입니다. 서버를 꺼 둬도(`stop`) 고정 IP 값은 계속 나갑니다.
느리면 `e2-small` 로 올립니다 (월 15달러쯤 더).

## 만들기 — Cloud Shell 에 붙여 넣기

0. 먼저 게임을 한 번 배포해 둡니다 (서버 파일이 게임과 같이 올라갑니다).
1. [console.cloud.google.com](https://console.cloud.google.com) → 오른쪽 위 `>_` (Cloud Shell) 을 엽니다.
2. 아래를 통째로 붙여 넣고 Enter. 몇 분 걸립니다.

```bash
PROJECT=our-office-jkjh
REGION=asia-northeast3
ZONE=asia-northeast3-a
gcloud config set project $PROJECT
gcloud services enable compute.googleapis.com secretmanager.googleapis.com firestore.googleapis.com

# 고정 IP — 주소가 안 바뀌어야 게임이 늘 같은 곳에 붙는다
gcloud compute addresses create office-ip --region=$REGION
IP=$(gcloud compute addresses describe office-ip --region=$REGION --format='value(address)')

# 80(인증서 받기) · 443(게임 연결)만 연다
gcloud compute firewall-rules create office-web --allow=tcp:80,tcp:443 --target-tags=office-server

# VM 의 서비스 계정에 저장(Firestore)과 비밀(제미나이 키)을 읽고 쓸 권한을 준다
SA=$(gcloud iam service-accounts list --filter="email~compute@developer" --format='value(email)')
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:$SA" --role=roles/datastore.user --condition=None
gcloud projects add-iam-policy-binding $PROJECT --member="serviceAccount:$SA" --role=roles/secretmanager.secretAccessor --condition=None

# VM — 켜질 때마다 setup.sh 가 설치 · 업데이트를 맡는다
gcloud compute instances create office-server --zone=$ZONE \
  --machine-type=e2-micro --image-family=debian-12 --image-project=debian-cloud \
  --boot-disk-size=10GB --address=$IP --tags=office-server \
  --service-account=$SA --scopes=cloud-platform \
  --metadata=startup-script='#!/bin/bash
curl -fsSL https://sloven85.github.io/our-office-web/server/setup.sh | bash'

echo
echo "서버 주소: wss://${IP//./-}.sslip.io   ← 이걸 Claude 에게 알려 주세요"
```

3. 마지막 줄의 `wss://…sslip.io` 주소를 알려 주면, 게임(`godot/scripts/net/Net.gd` 의 `SERVER_URL`)에
   넣어 배포합니다. 그때부터 기기들이 서버에 붙습니다.

## 잘 도는지 보기

```bash
# 서버 기록 (들어온 사람 · 저장 · 키)
gcloud compute ssh office-server --zone=asia-northeast3-a -- sudo journalctl -u office-server -n 50 --no-pager
# 설치 기록 (처음 켤 때)
gcloud compute ssh office-server --zone=asia-northeast3-a -- sudo journalctl -u google-startup-scripts -n 80 --no-pager
```

정상이면 `서버: 8080 포트에서 기다립니다` 가 보이고, 게임에 들어가면 `서버: ○○(sabu) 들어옴 · 1명` 이 찍힙니다.
게임 화면 위쪽 시계 줄에는 `· 서버 사무실 보는 중` 이 붙습니다.

## 끄기 · 켜기 · 지우기

```bash
gcloud compute instances stop  office-server --zone=asia-northeast3-a   # 끄기 (게임은 기기 혼자 돌기로)
gcloud compute instances start office-server --zone=asia-northeast3-a   # 켜기
# 완전히 지우기 (고정 IP 까지)
gcloud compute instances delete office-server --zone=asia-northeast3-a
gcloud compute addresses delete office-ip --region=asia-northeast3
```

## 파일

| 파일 | 하는 일 |
| --- | --- |
| `setup.sh` | VM 이 켜질 때마다 돈다. Godot 4.3(리눅스) · Caddy 설치, 서비스 등록, 첫 빌드 받기 |
| `office-server.service` | 게임 서버 (`godot --headless --main-pack index.pck -- --server`). 죽으면 다시 켠다 |
| `update.sh` · `office-update.timer` | 5분마다 새 빌드(`OFFICE_BUILD`)를 보고, 바뀌었으면 받아서 다시 켠다 |
| `Caddyfile` | `https`/`wss` 보안 연결. 인증서는 자동 (`<IP>.sslip.io`) |

## 안 될 때

- **게임이 서버에 안 붙고 혼자 돈다** — `journalctl -u office-server` 를 봅니다.
  - `저장을 못 읽었습니다 (403)` → 위의 `datastore.user` 권한 줄을 다시 붙여 넣습니다.
  - `제미나이 키를 못 받았습니다` → `secretAccessor` 권한 줄. (키가 없어도 저장에 든 키로 답합니다)
- **`명단에 없는 계정입니다`** — 들어온 계정이 `StaffData.PLAYERS` 에 없습니다. 두 사람 계정만 받습니다.
- **인증서가 안 나온다** — 방화벽 80 · 443 이 열려 있는지, `journalctl -u caddy` 를 봅니다.
