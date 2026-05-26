# 샘플 저장소 CI/CD 검증 진행 문서

> 작성일: 2026-05-23
> 갱신일: 2026-05-25 — 2단계(Docker 빌드/푸시) 전체 확장·검증 완료. **15개 중 14개 publish 통과**, `Samplepython2`만 기존 보안 스캔 단계 이슈로 의도적 차단(보존 결정)
> 대상: GitHub 샘플 저장소 15개 (Java 5 + Python 5 + JavaScript 5)
> 목적: CI/CD 자동화 파이프라인이 다양한 언어·구조의 프로젝트에서 동작하는지 검증

---

## 1. 개요 박범서 바보

`LibraryManagement_v1.2` 본 프로젝트에서 검증한 CI/CD 패턴(GitHub Actions → 빌드/테스트 → Docker Hub 푸시)을 **언어별 5개씩 총 15개 샘플 저장소**에 적용하여 범용성을 확인한다.

- **저장소 출처**: `jongha021229` (Java 5개), `moddak2` (Python 5개 + JS 5개)
- **작업 계정**: `hyckju` (fork 후 본인 계정에서 작업)
- **로컬 작업 디렉터리**: `C:\Git\ci-samples\{java,python,javascript}\`

---

## 2. 진행 전략

언어별 1개 저장소로 **파일럿** → 통과 시 나머지 4개로 **확장**.
단계도 둘로 쪼개서 진행 (한 번에 다 넣지 않음).

```
1단계: Build + Testzzzzzzzzzzzzzzzz
  └─ Java 1개 → 검증 → Java 4개 확장
  └─ Python 1개 → 검증 → Python 4개 확장
  └─ JavaScript 1개 → 검증 → JavaScript 4개 확장
2단계: Docker 이미지 빌드/푸시 추가
  └─ Java 1개 파일럿 → 검증
  └─ Python 1개 + JavaScript 1개 동시 → 검증
  └─ 나머지 12개로 확장  ✅ 완료 (2026-05-25) — 11개 통과 + py2 의도적 차단
```

---

## 3. 저장소 목록 및 상태

> Docker 컬럼 범례: ✅ 통과 = 실제 빌드·푸시 성공 확인 / ⏸️ 차단(의도적) = 기존 워크플로우 보존 결정으로 publish skip

| # | 언어 | 저장소 | 빌드/테스트 | Docker 빌드/푸시 |
|---|------|--------|:----------:|:---------------:|
| 1 | Java | `sample_java1` | ✅ 통과 | ✅ 통과 (파일럿) |
| 2 | Java | `sample_java2` | ✅ 통과 | ✅ 통과 (2026-05-25) |
| 3 | Java | `sample_java3` | ✅ 통과 | ✅ 통과 (2026-05-25) |
| 4 | Java | `sample_java4` | ✅ 통과 | ✅ 통과 (2026-05-25) |
| 5 | Java | `sample_java5` | ✅ 통과 | ✅ 통과 (2026-05-25) |
| 6 | Python | `Samplepython1` | ✅ 통과 | ✅ 통과 (파일럿) |
| 7 | Python | `Samplepython2` | ⚠️ test/build 단계는 통과하나 기존 scan 단계에서 job 실패 (semgrep 미설치) | ⏸️ 차단(의도적) — 기존 워크플로우 보존 결정으로 미수정, publish는 상위 job 실패로 skip |
| 8 | Python | `Samplepython3` | ✅ 통과 | ✅ 통과 (2026-05-25) |
| 9 | Python | `Samplepython4` | ✅ 통과 | ✅ 통과 (2026-05-25) |
| 10 | Python | `Samplepython5` | ✅ 통과 | ✅ 통과 (2026-05-25) |
| 11 | JavaScript | `SampleJavascript` | ✅ 통과 | ✅ 통과 (파일럿) |
| 12 | JavaScript | `Samplejavascript2` | ✅ 통과 | ✅ 통과 (2026-05-25) |
| 13 | JavaScript | `Samplejavascript3` | ✅ 통과 | ✅ 통과 (2026-05-25) |
| 14 | JavaScript | `Samplejavascript4` | ✅ 통과 | ✅ 통과 (2026-05-25) |
| 15 | JavaScript | `Samplejavascript5` | ✅ 통과 | ✅ 통과 (2026-05-25, 시크릿 수정 후 재실행) |

### 3.1 검증 방법 및 최종 결과 (2026-05-25)

**무엇을 테스트했나** — 각 fork의 `main`에 변경분(`ci.yml` publish job + `Dockerfile`)을 푸시하면 GitHub Actions가 다음을 실제 실행:

1. **build/test job** — 언어별 빌드·테스트 (Java: `gradle build` + JUnit / Python: `pytest`·`unittest`·`run_tests.py` / JS: `npm run build` + `npm test`)
2. **publish job** — Docker Hub 로그인 → `docker/build-push-action`으로 이미지 빌드 → `latest` + `sha-<short>` 태그로 푸시 (main 푸시 시에만)

**어떻게 확인했나** — 푸시 후 각 repo의 GitHub Actions 최신 run을 GitHub REST API(`/actions/runs`)로 조회해 `conclusion`(success/failure) 확인. 실패 건은 `/actions/runs/{id}/jobs`로 실패 step까지 특정.

**언어별 결과**

| 언어 | 신규 푸시·검증 | 결과 |
|------|----------------|------|
| JavaScript | `Samplejavascript2`~`5` (4개) | **4/4 통과** (js5는 시크릿 수정 후 재실행하여 통과) |
| Python | `Samplepython2`~`5` (4개) | **3/4 통과** (py3·4·5), `Samplepython2`는 기존 scan 단계 실패로 차단 |
| Java | `sample_java2`~`5` (4개) | **4/4 통과** |

**종합: 파일럿 3개 포함 15개 중 14개 build→publish 통과. `Samplepython2` 1개만 의도적 차단(아래 5번·7번 참조).**

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
| Java | `gradle:8.7-jdk17` (build) → `eclipse-temurin:17-jre` (runtime) | 멀티스테이지, `gradle build -x test` 후 jar 복사, `EXPOSE 8080` |
| Python | `python:3.11-slim` | `pip install -r requirements.txt` → FastAPI 앱은 `uvicorn <module>:app --host 0.0.0.0 --port 8000`, `EXPOSE 8000` |
| JavaScript | `node:20-alpine` | `npm ci --omit=dev`(lock 있을 때) / `npm install --omit=dev`(lock 없을 때) → 프로젝트 성격별 진입점 (서버/라이브러리/데모) |

> Java 5개는 동일한 멀티스테이지 Dockerfile. Python·JavaScript는 프로젝트마다 진입점이 달라 아래 4.7에 개별 정리.

### 4.6 이미지 태그 정책 (`docker/metadata-action@v5`)

- `latest` — main 브랜치 최신
- `sha-<short>` — 커밋 단위 추적용

### 4.7 프로젝트별 Dockerfile 진입점 / 이미지명 (2026-05-25 확장분)

`IMAGE_NAME`은 Docker 규칙상 모두 소문자로 통일.

**Java** (5개 모두 동일 패턴, Spring Boot + Gradle):

| 저장소 | 진입점 | EXPOSE | IMAGE_NAME |
|--------|--------|:------:|------------|
| `sample_java1`~`sample_java5` | `java -jar app.jar` (멀티스테이지 jar) | 8080 | `sample_java1`~`sample_java5` |

**Python** (모두 FastAPI, `uvicorn` 실행):

| 저장소 | 진입점 | EXPOSE | IMAGE_NAME | 비고 |
|--------|--------|:------:|------------|------|
| `Samplepython1` | `python -m secure_app` | 8000 | `samplepython1` | 파일럿, 패키지 설치형 |
| `Samplepython2` | `uvicorn app.main:app` | 8000 | `samplepython2` | scan job 보존, publish는 `needs: test-build-scan` |
| `Samplepython3` | `uvicorn app.main:app` | 8000 | `samplepython3` | |
| `Samplepython4` | `uvicorn main:app` | 8000 | `samplepython4` | 앱 진입점이 top-level `main.py` |
| `Samplepython5` | `uvicorn main:app` | 8000 | `samplepython5` | 앱 진입점이 top-level `main.py` |

**JavaScript** (프로젝트 성격별 진입점 상이):

| 저장소 | 진입점 | EXPOSE | IMAGE_NAME | 성격 / 설치 |
|--------|--------|:------:|------------|------|
| `SampleJavascript` | `node index.js` | 3000 | `samplejavascript` | 파일럿 |
| `Samplejavascript2` | `node src/run_demo.js` | 없음 | `samplejavascript2` | 데모 스크립트, lock 없어 `npm install` |
| `Samplejavascript3` | `node src/index.js` | 없음 | `samplejavascript3` | 라이브러리(서버 아님) |
| `Samplejavascript4` | `node src/server.js` | 3000 | `samplejavascript4` | Express 서버 |
| `Samplejavascript5` | `node src/server.js` | 3000 | `samplejavascript5` | Express 서버 |

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
| Docker(2단계 확장) | `Samplepython2` publish job을 어디에 매달까 | 기존 단일 job 이름이 `build`가 아니라 `test-build-scan` | publish의 `needs:`를 `test-build-scan`으로 지정 (타 Python은 `build`) |
| Docker(2단계 확장) | `Samplejavascript2` Dockerfile에서 `npm ci` 불가 | `package-lock.json` 없음 (build job도 `npm install` 사용) | Dockerfile도 `npm install --omit=dev`로 작성 |
| Docker(2단계 확장) | 일부 JS 프로젝트는 서버가 아님 | `Samplejavascript2`(데모), `Samplejavascript3`(라이브러리)는 listen 포트 없음 | `EXPOSE` 생략, CMD는 각각 `run_demo.js` / `index.js` 실행 |
| Docker(2단계 확장) | Python 진입점 모듈 경로 상이 | `py2/py3`는 `app/main.py`, `py4/py5`는 top-level `main.py` | uvicorn 대상을 각각 `app.main:app` / `main:app`으로 구분 |
| 검증(2단계) | `Samplejavascript5` publish "Log in to Docker Hub" 실패 | 해당 repo 시크릿 누락/오타 (js2~4는 동일 단계 통과) | 시크릿 수정 후 재실행하여 통과 |
| 검증(2단계) | `Samplepython2` scan 단계 실패로 job 실패 → publish skip | 기존 워크플로우가 `run_security_scan.sh`로 semgrep 호출하나 `requirements.txt`에 semgrep 없음. GitHub 첫 실행에서 노출(이전 run 이력 없음) | **사용자 결정: 기존 워크플로우 보존 우선, 미수정.** py2 Docker publish는 차단 상태 유지 |

---

## 6. 산출물 (저장소별)

각 fork된 저장소에 다음 파일이 추가됨 (2026-05-25 기준 **15개 전 저장소** 보유):

```
<repo>/
├── .github/workflows/ci.yml   ← 빌드/테스트 + publish job (전 15개)
└── Dockerfile                  ← Java 멀티스테이지 / Python·JS 단일스테이지 (전 15개)
```

빌드 산출물(이미지) — **실제 빌드·푸시 완료: 14개** (`hyckju/<IMAGE_NAME>:{latest, sha-<short>}` 형식):

| 언어 | 푸시된 이미지 (`hyckju/...`) |
|------|------------------------------|
| Java (5/5) | `sample_java1` ~ `sample_java5` |
| Python (4/5) | `samplepython1`, `samplepython3`, `samplepython4`, `samplepython5` |
| JavaScript (5/5) | `samplejavascript`, `samplejavascript2` ~ `samplejavascript5` |

> `samplepython2`는 미푸시 — 기존 보안 스캔 단계 실패로 publish job이 skip됨(의도적 보존). 시크릿은 추가돼 있어, scan 이슈만 해소되면 그대로 푸시 가능.

---

## 7. 진행 과정에서의 주요 의사결정

- **fork 방식 채택**: 원본 저장소에 push 권한이 없어 본인 계정으로 fork 후 작업. CI/CD는 fork된 저장소에서 독립적으로 실행.
- **로컬 디렉터리 분리**: 본 프로젝트(`LibraryManagement_v1.2`)에 중첩하지 않고 `C:\Git\ci-samples\` 별도 경로 사용. 부모 git과 충돌 방지.
- **레지스트리는 Docker Hub로 통일**: 본 프로젝트와 동일한 레지스트리로 운영 일관성 확보. (대안 GHCR은 무료/시크릿 불필요 장점이 있으나 본 프로젝트 패턴과 다름)
- **단계 분리 (Build/Test → Docker)**: 한 번에 모든 단계 넣지 않고 빌드/테스트 통과 검증 후 Docker 단계 추가. 디버깅 비용 절감.
- **언어별 파일럿 우선**: 15개를 한꺼번에 작성하지 않고 언어별 1개로 패턴 검증 후 4개씩 확장. 같은 실수의 15회 반복 방지.

---

## 8. 향후 과제

- [x] Docker 빌드/푸시 단계(ci.yml publish job + Dockerfile)를 나머지 12개 저장소로 확장 — **완료 (2026-05-25)**
- [x] 12개 저장소 각각에 `DOCKER_HUB_USERNAME` + `DOCKER_HUB_TOKEN` 시크릿 추가 → main 푸시로 **실제 빌드·푸시 검증** — **완료 (14/15 통과)**
- [ ] `Samplepython2` 보안 스캔 단계 정상화 (semgrep 설치 또는 non-blocking 처리) → publish 차단 해소
- [ ] PR 기반 미리보기 이미지 태그 정책 도입 (현재는 main 푸시만 푸시)
- [ ] 보안 스캔(Trivy, gitleaks 등) 단계 추가 (`Samplejavascript`는 이미 `.gitleaks.toml`, `.semgrep.yml` 포함)
- [ ] 멀티 아키텍처 이미지 빌드(`linux/amd64`, `linux/arm64`) 고려
- [ ] 본 프로젝트(`LibraryManagement_v1.2`)와의 차이점/공통점을 통합한 워크플로우 템플릿화