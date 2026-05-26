# CI/CD 구축 문서

> 저장소: [hyckju/Library-CICD](https://github.com/hyckju/Library-CICD)
> 작성일: 2026-05-20
> 대상 프로젝트: `LibraryManagement_v1.2`

---

## 1. 박범서 바보

기존 도서관리 시스템(`LibraryManagement_v1.2`)은 순수 `javac` 컴파일 기반이라 의존성 관리·자동화 빌드·배포가 어려웠다. 이를 해결하기 위해 다음을 도입했다.

- **Maven** 기반 빌드 체계로 전환
- **GitHub Actions** 워크플로우로 테스트·빌드·배포 자동화
- **MariaDB 서비스 컨테이너**를 띄워 통합 테스트 실행
- **Docker Hub**로 이미지 자동 푸시 (CD)

---

## 2. 시스템 구성

```
┌─────────────────────────────────────────────────────────────┐
│  GitHub (push / pull_request → main)                        │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions: .github/workflows/ci-cd.yml                │
│                                                             │
│   ┌──────────────────────┐    ┌──────────────────────────┐  │
│   │  job: test           │    │  job: publish            │  │
│   │  (PR & push)         │───▶│  (push to main 만)       │  │
│   │                      │    │                          │  │
│   │  · MariaDB service   │    │  · Docker Buildx         │  │
│   │  · JDK 17 (Temurin)  │    │  · Docker Hub login      │  │
│   │  · init.sql 적재     │    │  · build & push          │  │
│   │  · mvn -B test       │    │    (latest, sha-xxxx)    │  │
│   │  · surefire 업로드   │    │                          │  │
│   └──────────────────────┘    └──────────┬───────────────┘  │
│                                          │                  │
└──────────────────────────────────────────┼──────────────────┘
                                           ▼
                                  ┌──────────────────┐
                                  │   Docker Hub     │
                                  │  library-cicd    │
                                  └──────────────────┘
```

---

## 3. 주요 산출물

| 경로 | 역할 |
|---|---|
| `.github/workflows/ci-cd.yml` | CI/CD 파이프라인 정의 |
| `LibraryManagement_v1.2/pom.xml` | Maven 빌드·의존성 정의 (MariaDB JDBC, JUnit 5) |
| `LibraryManagement_v1.2/dockerfile` | Maven 멀티스테이지 빌드 이미지 정의 |
| `LibraryManagement_v1.2/ci/init.sql` | CI MariaDB 컨테이너용 스키마/시드 |
| `LibraryManagement_v1.2/src/LibraryRepository.java` | `System.getenv()` 기반 DB 접속정보 주입 |

---

## 4. 워크플로우 상세

### 4.1 트리거

```yaml
on:
  push:         { branches: [main] }
  pull_request: { branches: [main] }
```

- `main` 푸시·PR 모두 `test` job 실행
- `publish` job은 `main` 직접 푸시일 때만 실행 (`if: github.event_name == 'push' && github.ref == 'refs/heads/main'`)

### 4.2 test job

- **러너**: `ubuntu-latest`
- **서비스 컨테이너**: `mariadb:11` (포트 3306, 헬스체크 포함)
- **DB 환경변수**: `DB_URL=jdbc:mariadb://127.0.0.1:3306/library`, `DB_USER=cjulib`, `DB_PASSWORD=security`
- **단계**:
  1. `actions/checkout@v4`
  2. `actions/setup-java@v4` (Temurin 17, Maven 캐시)
  3. `mariadb-client` 설치 후 `ci/init.sql` 적재
  4. `mvn -B test`
  5. `target/surefire-reports/`를 아티팩트로 업로드 (`if: always()`)

### 4.3 publish job (CD)

- `needs: test` — 테스트 통과 후에만 실행
- **이미지명**: `${{ secrets.DOCKER_HUB_USERNAME }}/library-cicd`
- **태그**: `latest`, `sha-<short>` (docker/metadata-action v5)
- **빌드 캐시**: GitHub Actions Cache (`type=gha`)

### 4.4 필요 시크릿

| 이름 | 용도 |
|---|---|
| `DOCKER_HUB_USERNAME` | Docker Hub 사용자명 |
| `DOCKER_HUB_TOKEN` | Docker Hub Personal Access Token (PAT) |

> Docker Hub 계정은 GitHub OAuth로 가입되어 비밀번호가 없으므로, **반드시 PAT**를 사용해야 한다.

---

## 5. Dockerfile (멀티스테이지)

```
Stage 1: maven:3.9-eclipse-temurin-17
  ├─ pom.xml 복사 → mvn dependency:go-offline (캐시 최적화)
  └─ src/test 복사 → mvn package -DskipTests
Stage 2: eclipse-temurin:17-jre
  ├─ /app/target/library-management-1.2.0.jar → app.jar
  └─ /app/target/lib → lib
ENTRYPOINT: java -jar app.jar
```

- 테스트는 CI에서 이미 수행하므로 이미지 빌드 시 `-DskipTests`
- JRE-only 이미지로 최종 사이즈 절감

---

## 6. 작업 이력 (Commit History)

| 날짜 | 커밋 | 변경 내용 |
|---|---|---|
| 2026-05-14 | `5728e98` | Initial commit |
| 2026-05-14 | `67bfd00` | LibraryManagement_v1.2 Javadoc 초기 작성 |
| 2026-05-14 | `7d22557` | LICENSE/README 제거, Dockerfile을 Maven 기반으로 수정, 워크플로우 초안 |
| 2026-05-14 | `1db355c` | Maven 기반 CI/CD 워크플로우와 프로젝트 설정 추가 |
| 2026-05-15 | `df523fb` | DB 스키마 init 스크립트 도입, DB 접속 정보를 환경변수로 분리 |
| 2026-05-17 | `2f76f6d` | 레지스트리를 GHCR → Docker Hub로 전환, JUnit 6 정리, IntelliJ 설정 조정 |
| 2026-05-17 | `a680eb6` | CI/CD 워크플로우 테스트 실행 |
| 2026-05-17 | `d06b691` | Docker Hub 시크릿 변수명 오타 1차 수정 |
| 2026-05-17 | `c950cd5` | Docker Hub 시크릿 변수명 오타 2차 수정 |
| 2026-05-17 | `14b9f73` | Docker Hub 시크릿 변수명 오타 최종 정정 |
| 2026-05-17 | `1ad6f9e` | Docker Hub 시크릿 갱신 후 CI 재트리거 |

### 6.1 진행 과정에서의 주요 의사결정

- **GHCR → Docker Hub 전환** (`2f76f6d`): 초기에는 GitHub Container Registry(GHCR)와 `GITHUB_TOKEN`을 사용할 계획이었으나, 패키지 권한 문제 (Issue #3)와 운영 편의성을 고려해 Docker Hub로 변경.
- **DB 접속 정보 환경변수화** (`df523fb`): `LibraryRepository`가 하드코딩된 사설망 IP(`192.168.100.20`)를 사용했기 때문에 CI 환경에서 접속 불가. `System.getenv().getOrDefault(...)`로 우회 가능하도록 변경.
- **CI 전용 스키마 스크립트** (`df523fb`): `ci/init.sql`로 `users`, `books` 테이블 생성 및 기본 계정(admin/1111, user/2222) 시드. CI MariaDB 서비스 컨테이너 기동 직후 `mariadb-client`로 적재.

---

## 7. GitHub Issues

[전체 이슈 보기](https://github.com/hyckju/Library-CICD/issues)

### 열린 이슈

| # | 제목 | 라벨 | 현황 / 설명 |
|---|---|---|---|
| [#1](https://github.com/hyckju/Library-CICD/issues/1) | Maven 빌드 도구 도입 | enhancement | 순수 javac → Maven 전환. **사실상 완료** (`pom.xml` 작성, `1db355c`). 이슈 클로즈만 남음. |
| [#2](https://github.com/hyckju/Library-CICD/issues/2) | 워크플로우 작성 | — | test/publish 2-job 구성. **완료** (`ci-cd.yml` 작성, `1db355c`, `2f76f6d`). 단, 본문에 명시된 GHCR 대상은 Docker Hub로 변경됨. |
| [#4](https://github.com/hyckju/Library-CICD/issues/4) | Docker Hub 연동 확인 | — | Docker Hub 시크릿(`DOCKER_HUB_USERNAME`/`DOCKER_HUB_TOKEN`) 설정 및 푸시 검증. 시크릿 오타 수정 3회 후 (`d06b691`, `c950cd5`, `14b9f73`) `1ad6f9e`로 재트리거. |
| [#5](https://github.com/hyckju/Library-CICD/issues/5) | `mvn test` 실행 | — | test job에서 `mvn -B test` 수행. **완료**. MariaDB 서비스 컨테이너와 `ci/init.sql` 적재까지 함께 구성. |
| [#6](https://github.com/hyckju/Library-CICD/issues/6) | Dockerfile을 Maven 멀티스테이지 빌드로 전환 | — | 기존 컨테이너 내부 javac 빌드 → Maven 멀티스테이지. **완료** (`dockerfile`, `7d22557`). |
| [#7](https://github.com/hyckju/Library-CICD/issues/7) | Docker Hub 이미지 자동 푸시 (CD) | enhancement | main 푸시 시 자동 푸시. **완료** (publish job, `2f76f6d` 이후). 본문의 "AWS S3"는 실제 구현 시 Docker Hub로 변경됨. |

> 위 이슈들은 코드상으로는 모두 반영되었으나 GitHub 상태가 `open`으로 남아있다. 검증이 끝났다면 이슈를 닫는 작업이 필요.

### 닫힌 이슈

| # | 제목 | 닫힌 날짜 | 해결 방법 |
|---|---|---|---|
| [#3](https://github.com/hyckju/Library-CICD/issues/3) | GHCR 패키지 권한 수정 | 2026-05-20 | 레지스트리를 Docker Hub로 전환하면서 GHCR 관련 권한 이슈가 자연 해소됨 (`2f76f6d`). |

---

## 8. 시행착오 기록

| 증상 | 원인 | 해결 |
|---|---|---|
| publish job에서 Docker Hub 로그인 실패 | 워크플로우 내 시크릿 키 이름 오타 | `d06b691` → `c950cd5` → `14b9f73`으로 3차 정정, `1ad6f9e`로 재실행 검증 |
| CI에서 DB 연결 실패 | `LibraryRepository`가 사설망 IP를 하드코딩 | `System.getenv().getOrDefault(...)`로 환경변수 우선 사용 (`df523fb`) |
| Docker Hub 인증 시 비밀번호 사용 시도 | 해당 Docker Hub 계정은 GitHub OAuth 가입으로 비밀번호 미존재 | PAT(Personal Access Token) 발급 후 `DOCKER_HUB_TOKEN` 시크릿에 저장 |

---

## 9. 향후 과제

- [ ] 코드 반영 완료된 Issue #1, #2, #4, #5, #6, #7 클로즈 처리
- [ ] PR 기반 워크플로우 도입 (현재는 main 직접 푸시 중심)
- [ ] 정적 분석/취약점 스캔 단계 추가 (예: SpotBugs, Trivy)
- [ ] 통합 테스트 클래스 추가 (현재 `mvn test`만 정의되어 있고 실제 테스트 케이스 보강 필요)
- [ ] 운영 배포 단계 정의 (Docker Hub 푸시 → 실제 배포 환경 연결)
