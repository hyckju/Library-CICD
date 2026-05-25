# 샘플 저장소 CI/CD 검증 진행 문서

> 작성일: 2026-05-23
> 대상: GitHub 샘플 저장소 15개 (Java 5 + Python 5 + JavaScript 5)
> 목적: CI/CD 자동화 파이프라인이 다양한 언어·구조의 프로젝트에서 동작하는지 검증

---

## 1. 개요

`LibraryManagement_v1.2` 본 프로젝트에서 검증한 CI/CD 패턴(GitHub Actions → 빌드/테스트 → Docker Hub 푸시)을 **언어별 5개씩 총 15개 샘플 저장소**에 적용하여 범용성을 확인한다.

- **저장소 출처**: `jongha021229` (Java 5개), `moddak2` (Python 5개 + JS 5개)
- **작업 계정**: `hyckju` (fork 후 본인 계정에서 작업)
- **로컬 작업 디렉터리**: `C:\Git\ci-samples\{java,python,javascript}\`

---

## 2. 진행 전략

언어별 1개 저장소로 **파일럿** → 통과 시 나머지 4개로 **확장**.
단계도 둘로 쪼개서 진행 (한 번에 다 넣지 않음).

```
1단계: Build + Test 통과아아
  └─ Java 1개 → 검증 → Java 4개 확장
  └─ Python 1개 → 검증 → Python 4개 확장
  └─ JavaScript 1개 → 검증 → JavaScript 4개 확장
2단계: Docker 이미지 빌드/푸시 추가
  └─ Java 1개 파일럿 → 검증
  └─ Python 1개 + JavaScript 1개 동시 → 검증
  └─ 나머지 12개로 확장  ← 현재 위치
```

---

## 3. 저장소 목록 및 상태

| # | 언어 | 저장소 | 빌드/테스트 | Docker 빌드/푸시 |
|---|------|--------|:----------:|:---------------:|
| 1 | Java | `sample_java1` | ✅ 통과 | ✅ 통과 (파일럿) |
| 2 | Java | `sample_java2` | ✅ 통과 | ⏳ 대기 |
| 3 | Java | `sample_java3` | ✅ 통과 | ⏳ 대기 |
| 4 | Java | `sample_java4` | ✅ 통과 | ⏳ 대기 |
| 5 | Java | `sample_java5` | ✅ 통과 | ⏳ 대기 |
| 6 | Python | `Samplepython1` | ✅ 통과 | ✅ 통과 (파일럿) |
| 7 | Python | `Samplepython2` | ✅ 통과 (기존 워크플로우 보존) | ⏳ 대기 |
| 8 | Python | `Samplepython3` | ✅ 통과 | ⏳ 대기 |
| 9 | Python | `Samplepython4` | ✅ 통과 | ⏳ 대기 |
| 10 | Python | `Samplepython5` | ✅ 통과 | ⏳ 대기 |
| 11 | JavaScript | `SampleJavascript` | ✅ 통과 | ✅ 통과 (파일럿) |
| 12 | JavaScript | `Samplejavascript2` | ✅ 통과 | ⏳ 대기 |
| 13 | JavaScript | `Samplejavascript3` | ✅ 통과 | ⏳ 대기 |
| 14 | JavaScript | `Samplejavascript4` | ✅ 통과 | ⏳ 대기 |
| 15 | JavaScript | `Samplejavascript5` | ✅ 통과 | ⏳ 대기 |

---

## 4. 워크플로우 패턴

### 4.1 공통 트리거

```yaml
on:
  push:         { branches: [main, master] }
  pull_request: { branches: [main, master] }
```

### 4.2 publish job 조건

- `needs: build` — 빌드/테스트 통과 후에만 실행
- `if: github.event_name == 'push' && github.ref == 'refs/heads/main'` — PR에선 푸시 안 함

### 4.3 필요 시크릿 (저장소별)

| 이름 | 용도 |
|---|---|
| `DOCKER_HUB_USERNAME` | Docker Hub 사용자명 |
| `DOCKER_HUB_TOKEN` | Docker Hub PAT |

> 본 프로젝트와 동일한 시크릿. Docker Hub 계정이 OAuth 가입이라 비밀번호가 없으므로 **PAT 필수**.

### 4.4 언어별 빌드/테스트 단계

| 언어 | 핵심 단계 |
|------|----------|
| Java | `setup-java@v4` (Temurin 17) + `gradle/actions/setup-gradle@v4` (Gradle 8.7 설치) → `gradle build` |
| Python | `setup-python@v5` (3.11, pip 캐시) → `pip install -r requirements.txt` → `pytest` (또는 unittest) |
| JavaScript | `setup-node@v4` (Node 20, npm 캐시) → `npm ci` → `npm run build` → `npm test` |

### 4.5 Dockerfile 패턴

| 언어 | 베이스 이미지 | 패턴 |
|------|------------|------|
| Java | `gradle:8.7-jdk17` (build) → `eclipse-temurin:17-jre` (runtime) | 멀티스테이지, `gradle build -x test` 후 jar 복사 |
| Python | `python:3.11-slim` | requirements.txt 설치 → `pip install -e .` → `python -m secure_app` |
| JavaScript | `node:20-alpine` | `npm ci --omit=dev` → `node index.js` |

### 4.6 이미지 태그 정책 (`docker/metadata-action@v5`)

- `latest` — main 브랜치 최신
- `sha-<short>` — 커밋 단위 추적용

---

## 5. 시행착오 기록

| 영역 | 증상 | 원인 | 해결 |
|------|------|------|------|
| Java | `Could not find or load main class "-Xmx64m"` | `gradle-wrapper.jar` 누락 (`.gitignore`의 `*.jar`가 wrapper jar도 제외) + `gradlew` CRLF 줄바꿈 | wrapper 우회: `setup-gradle@v4`에 `gradle-version: '8.7'` 지정, `./gradlew` 대신 `gradle` 명령 사용 |
| Python | `pytest: command not found` | `Samplepython4`의 `requirements.txt`에 pytest 없음 + 테스트가 stdlib `unittest` 사용 | 테스트 명령을 `python -m unittest discover -s tests`로 변경 |
| Python | `ModuleNotFoundError: No module named 'app'` | `Samplepython3`이 multi top-level layout이라 `pip install -e .` 실패 → pytest가 `app` 패키지 못 찾음 | `pip install -e .` 단계 제거 + `env: PYTHONPATH: .` 지정하여 pytest 실행 |
| Python | `Samplepython5` pyproject.toml 없음 + tests가 unittest | 표준 pyproject 패턴 미적용 | `requirements-dev.txt`도 설치 + `python run_tests.py` 실행 |
| JavaScript | `Dependencies lock file is not found` | `Samplejavascript2`에 `package-lock.json` 없음 | `cache: 'npm'` 제거 + `npm ci` → `npm install`로 변경 |
| Python | `Samplepython2` 기존 워크플로우 존재 (venv + 보안 스캔) | 사용자가 직접 작성한 워크플로우가 이미 동작 중 | 덮어쓰지 않고 보존 (기존 워크플로우 그대로 통과 확인) |

---

## 6. 산출물 (저장소별)

각 fork된 저장소에 다음 파일이 추가됨:

```
<repo>/
├── .github/workflows/ci.yml   ← 빌드/테스트 (+ publish job, 1단계 진행분)
└── Dockerfile                  ← 멀티스테이지 또는 단일스테이지 (2단계 파일럿 진행분)
```

빌드 산출물(이미지):

| 저장소 | Docker Hub 이미지 |
|--------|-------------------|
| `sample_java1` | `hyckju/sample_java1:{latest, sha-xxxx}` |
| `Samplepython1` | `hyckju/samplepython1:{latest, sha-xxxx}` |
| `SampleJavascript` | `hyckju/samplejavascript:{latest, sha-xxxx}` |

---

## 7. 진행 과정에서의 주요 의사결정

- **fork 방식 채택**: 원본 저장소에 push 권한이 없어 본인 계정으로 fork 후 작업. CI/CD는 fork된 저장소에서 독립적으로 실행.
- **로컬 디렉터리 분리**: 본 프로젝트(`LibraryManagement_v1.2`)에 중첩하지 않고 `C:\Git\ci-samples\` 별도 경로 사용. 부모 git과 충돌 방지.
- **레지스트리는 Docker Hub로 통일**: 본 프로젝트와 동일한 레지스트리로 운영 일관성 확보. (대안 GHCR은 무료/시크릿 불필요 장점이 있으나 본 프로젝트 패턴과 다름)
- **단계 분리 (Build/Test → Docker)**: 한 번에 모든 단계 넣지 않고 빌드/테스트 통과 검증 후 Docker 단계 추가. 디버깅 비용 절감.
- **언어별 파일럿 우선**: 15개를 한꺼번에 작성하지 않고 언어별 1개로 패턴 검증 후 4개씩 확장. 같은 실수의 15회 반복 방지.

---

## 8. 향후 과제

- [ ] Docker 빌드/푸시 단계를 나머지 12개 저장소로 확장
- [ ] 12개 저장소 각각에 `DOCKER_HUB_USERNAME` + `DOCKER_HUB_TOKEN` 시크릿 추가
- [ ] PR 기반 미리보기 이미지 태그 정책 도입 (현재는 main 푸시만 푸시)
- [ ] 보안 스캔(Trivy, gitleaks 등) 단계 추가 (`Samplejavascript`는 이미 `.gitleaks.toml`, `.semgrep.yml` 포함)
- [ ] 멀티 아키텍처 이미지 빌드(`linux/amd64`, `linux/arm64`) 고려
- [ ] 본 프로젝트(`LibraryManagement_v1.2`)와의 차이점/공통점을 통합한 워크플로우 템플릿화