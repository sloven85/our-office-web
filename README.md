# 끄적끄적문구 사무실 — 웹 빌드

동물 직원 15명이 출근하고, 일하고, 수다 떨고, 퇴근하는 사무실을 지켜보는 게임입니다.

▶ **https://sloven85.github.io/our-office-web/**

이 저장소에는 Godot 으로 내보낸 웹 빌드만 들어 있습니다. 소스는 비공개 저장소에
있고, 거기에 푸시가 있을 때마다 GitHub Actions 가 이 저장소를 통째로 갈아끼웁니다.
(그래서 이 저장소의 커밋 히스토리는 항상 한 개입니다)

▶ 안드로이드: **https://sloven85.github.io/our-office-web/office.apk**
(출처를 알 수 없는 앱 설치를 허용해야 깔립니다 — 스토어에 안 올린 APK라 그렇습니다)

## 캐릭터 도트 편집실

▶ **https://sloven85.github.io/our-office-web/sprite-editor.html**

직원·식당 직원·방문객 등 33개 캐릭터를 선택하고 4방향/5동작의 도트를 수정합니다.
편집 파일(.json)을 저장해 다시 열거나 전달할 수 있습니다. 게임/세이브에 자동 적용되지 않습니다.

오프라인 편집실: [sprite-editor-offline.html](https://sloven85.github.io/our-office-web/sprite-editor-offline.html)을 저장해 브라우저로 여세요.
기존 `leenote-editor.html` 주소도 공용 편집실로 연결됩니다.

소스 빌드: `d6266ea`. 편집실은 소스 저장소의 `godot/tools/build_sprite_editor.sh`로 패키징했습니다.
현재 게임 CI는 이 배포 저장소를 통째로 교체하므로, 자동 복사 연결을 추가하기 전에는
게임 재배포 후 편집실 파일도 별도로 다시 배포해야 합니다.
