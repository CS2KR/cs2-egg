# 소스에서 빌드하기

Docker 이미지를 직접 만드는 방법입니다.

## 준비물

- Docker
- Git
- 기본적인 명령줄 사용법

## 평소에는 빌드할 필요가 없습니다

`main` 브랜치의 `docker/` 가 바뀌면 GitHub Actions(`.github/workflows/build-image.yml`)가 이미지를
자동으로 빌드해 `ghcr.io/cs2kr/cs2-egg:latest` 와 커밋 SHA 태그로 올립니다. 서버는 다음 기동 때 그것을 받습니다.

직접 빌드하는 경우는 이런 때입니다.

- 올리기 전에 로컬에서 시험하고 싶을 때
- 우리 저장소를 포크해 자기 레지스트리로 올릴 때

## 빠른 빌드

저장소의 `build.sh` 가 과정을 감싸 줍니다.

```bash
# 기본 'dev' 태그로 빌드
./build.sh

# 태그를 지정해 빌드
./build.sh latest

# 빌드하고 GHCR 로 바로 올리기
./build.sh latest -g

# 버전 태그로 빌드하고 올리기
./build.sh -t 1.2.3 -g
```

**옵션**

- `-t, --tag 태그` — 태그를 명시합니다 (기본 `dev`)
- `-g, --ghcr` — 빌드 뒤 `ghcr.io` 로 올립니다 (`-P`, `--publish` 도 같습니다)
- `-h, --help` — 도움말

**자기 레지스트리로 바꾸려면**

1. `build.sh` 를 엽니다.
2. `GITHUB_REPO` 를 자기 것으로 바꿉니다 (예: `yourname/cs2-egg`). GHCR 은 **소문자**만 받습니다.
3. 원하는 태그로 실행합니다.

## 직접 빌드하기

```bash
cd docker
docker build -f Dockerfile -t your-registry/your-image:tag .
```

## 레지스트리로 올리기

### GHCR

```bash
# 로그인 (write:packages 권한이 있는 토큰 필요)
echo "$GITHUB_TOKEN" | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# 올리기
docker push ghcr.io/cs2kr/cs2-egg:tag
```

> 조직 계정에서 **공개** 패키지를 만들려면 조직 설정
> (`https://github.com/organizations/<조직>/settings/packages`)에서 공개 패키지 생성을 먼저 허용해야 합니다.
> 그러지 않으면 패키지 설정의 *Change visibility* 가 `Setting is disabled by organization administrators` 로 막힙니다.

### 사설 레지스트리

```bash
docker login your-registry.com
docker tag your-registry/your-image:tag your-registry.com/your-image:tag
docker push your-registry.com/your-image:tag
```

## Pterodactyl 에서 내 이미지 쓰기

1. **Admin** → **Nests** → 해당 Nest → **Eggs** 로 갑니다.
2. `CS2.KR CS2 Egg` 를 고칩니다.
3. **Docker Images** 에 이미지를 추가합니다.
   ```json
   "내 이미지": "your-registry/your-image:tag"
   ```
4. 저장합니다.
5. 서버의 **Startup** 탭에서 그 이미지를 고릅니다.

### 비공개 레지스트리를 쓴다면

**모든 노드**에서 레지스트리에 로그인해야 합니다.

```bash
ssh root@your-node
docker login    # 또는 docker login your-registry.com
```

인증하지 않으면 컨테이너 생성이 `pull access denied` 로 실패합니다.

## 이미지 고치기

### 패키지 추가

`docker/Dockerfile` 을 고칩니다.

```dockerfile
ENV         DEBIAN_FRONTEND=noninteractive
RUN         apt update && \
            apt install -y iproute2 jq unzip rsync curl \
            your-new-package && \
            apt-get clean
```

### 스크립트 추가

1. `docker/scripts/` 또는 `docker/utils/` 에 스크립트를 만듭니다.
2. Dockerfile 이 디렉터리째 복사하므로 따로 손댈 필요는 없습니다.
   ```dockerfile
   COPY        ./scripts /scripts/
   COPY        ./utils /utils/
   ```
3. 실행 권한도 Dockerfile 에서 한꺼번에 줍니다.
   ```dockerfile
   RUN         chmod 555 /scripts/*.sh && \
               chmod 555 /scripts/updaters/*.sh && \
               chmod 555 /utils/*.sh
   ```

### entrypoint 고치기

기동 동작을 바꾸려면 `docker/entrypoint.sh` 를 고칩니다.

## 여러 아키텍처로 빌드

```bash
docker buildx create --name cs2-builder --use

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f docker/Dockerfile \
  -t your-registry/your-image:tag \
  --push \
  ./docker
```

## CI

이 저장소의 `.github/workflows/build-image.yml` 이 하는 일은 이렇습니다.

```yaml
on:
  push:
    branches: [main]
    paths:
      - "docker/**"
      - ".github/workflows/build-image.yml"
  workflow_dispatch:
```

- `docker/` 가 바뀔 때만 돕니다. 문서만 고치면 빌드하지 않습니다.
- 셸 문법 검사(`bash -n`)를 먼저 돌립니다.
- Actions 의 `GITHUB_TOKEN` 은 `packages: write` 권한을 기본으로 받으므로 별도 토큰이 필요 없습니다.
- `:latest` 와 커밋 SHA 태그를 함께 올립니다. 되돌릴 때 SHA 태그를 쓰면 됩니다.

## 빌드가 안 될 때

### apt install 에서 실패

```bash
docker builder prune
docker build --no-cache -f docker/Dockerfile -t your-image:tag ./docker
```

### 권한 오류

```bash
chmod +x build.sh
```

### 이미지가 너무 큼

- `RUN` 을 합치세요.
- 필요 없는 패키지를 빼세요.
- 설치 뒤 정리하세요 (`apt-get clean`).

## 권장 사항

1. **태그를 붙이세요.** 커밋 SHA 태그가 자동으로 붙지만, 배포용에는 버전 태그도 함께 다세요.
2. **올리기 전에 로컬에서 시험하세요.**
3. **베이스 이미지를 주기적으로 갱신하세요** (SteamRT).
4. **레이어를 줄이세요.**

## 도움 요청

- [이슈 열기](https://github.com/CS2KR/cs2-egg/issues/new)
