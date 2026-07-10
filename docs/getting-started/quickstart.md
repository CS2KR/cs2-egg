---
icon: download
---

# 설치와 적용

## 설치

1. 저장소에서 [egg 파일](../../pterodactyl/cs2kr-cs2-egg.json)을 내려받습니다.
2. Pterodactyl 패널의 원하는 Nest 로 import 합니다. 관리자 화면 → "Service Management" 의 "Nests" → "Import Egg" 순서입니다.

## 이미 있는 서버에 egg 적용하기

1. Pterodactyl 관리자 화면의 "Servers" 로 갑니다.
2. egg 를 적용할 서버를 고릅니다.
3. "Startup" 탭으로 갑니다.
4. <mark style="color:purple;">**Nest**</mark> 를 egg 가 들어 있는 Nest 로 지정합니다.
5. <mark style="color:purple;">**Egg**</mark> 를 <mark style="color:yellow;">**CS2.KR CS2 Egg**</mark> 로 지정합니다.
6. 파일이 지워지지 않도록 <mark style="color:purple;">**Skip Egg Install Script**</mark> 를 체크합니다.
7. <mark style="color:purple;">**Image**</mark> 를 원하는 egg 이미지로 지정합니다.
8. 저장합니다.

## 새 서버를 이 egg 로 만들기

1. "New Server" 화면에서 <mark style="color:purple;">**Nest Configuration**</mark> 이 보일 때까지 내립니다.
2. <mark style="color:purple;">**Nest**</mark> 를 egg 가 들어 있는 Nest 로 지정합니다.
3. <mark style="color:purple;">**Egg**</mark> 를 <mark style="color:yellow;">**CS2.KR CS2 Egg**</mark> 로 지정합니다.
4. <mark style="color:purple;">**Docker Image**</mark> 를 원하는 egg 이미지로 지정합니다.
5. 나머지 값을 채우고 서버를 만듭니다.
