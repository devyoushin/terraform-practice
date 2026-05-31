# {모듈명} 모듈

> **레이어**: {컴퓨팅 | 네트워크 | 데이터 | 보안 | 운영}
> **관련 AWS 서비스**: {서비스명}
> **작성일**: {YYYY-MM-DD}

---

## 개요

{이 모듈이 무엇을 프로비저닝하는지, 왜 필요한지 3문장 이내}

---

## 사전 요구사항

- [ ] {선행 모듈} 배포 완료
- [ ] AWS CLI 프로필 설정 (`AWS_PROFILE`)
- [ ] Terraform >= {버전}
- [ ] 필요한 IAM 권한: {권한 목록}

---

## 디렉토리 구조

```
{모듈명}/
├── modules/{모듈명}/
│   ├── main.tf          # 핵심 리소스 정의
│   ├── variables.tf     # 입력 변수
│   └── outputs.tf       # 출력값
├── envs/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars.example
│   │   └── backend.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars.example
│       └── backend.tf
├── Makefile
├── .pre-commit-config.yaml
└── README.md
```

---

## 주요 설정 값

| 변수 | dev | prod | 설명 |
|------|-----|------|------|
| `{변수명}` | `{dev 값}` | `{prod 값}` | {설명} |

---

## 배포 순서

```bash
# 1. 환경 변수 설정
export AWS_PROFILE=<PROFILE>
export ENV=dev  # 또는 prod

# 2. 초기화
make init ENV=$ENV

# 3. 플랜 검토
make plan ENV=$ENV

# 4. 적용 (prod는 플랜 파일 저장 후 적용)
make apply ENV=$ENV
```

---

## 배포 확인

```bash
{확인 AWS CLI 명령어}
```

**성공 기준**:
- [ ] {조건 1}
- [ ] {조건 2}

---

## 삭제

```bash
# dev 환경만 삭제 허용 (prod는 prevent_destroy 설정)
make destroy ENV=dev
```

> **주의**: {삭제 시 주의사항}

---

## 트러블슈팅

### {증상 1}

**원인**: {근본 원인}

**해결**:
```bash
{해결 명령어}
```

---

## 구현 체크리스트

- [ ] `### ===` 헤더 주석 포함
- [ ] project_name, environment(validation), common_tags 변수 포함
- [ ] dev/prod 환경별 설정 차이 적용
- [ ] terraform.tfvars.example 작성 (시크릿 제외)
- [ ] Makefile 표준 타겟 포함
- [ ] pre-commit 훅 설정
- [ ] README.md 작성 완료
