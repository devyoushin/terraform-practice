# Terraform 모듈 구축 가이드

이 문서는 이 저장소에서 Terraform/Terragrunt를 어떻게 읽고, 어떻게 새 모듈을 만들고, 어디를 고쳐야 하는지 정리한 안내서다.

이 저장소는 두 계층으로 나뉜다.

- `ops/dev`, `ops/prod`: Terragrunt 기반 실행 경로
- `ops/legacy`: 재사용 가능한 Terraform 모듈과 레거시 직접 실행 예제

---

## 먼저 결론

새 작업을 시작할 때는 아래 질문부터 답하면 된다.

| 질문 | 갈 곳 |
|------|-------|
| 전체 구조를 처음 본다 | `docs/README.md` |
| 새 모듈을 만들거나 구조를 바꾼다 | 이 문서 |
| 적용 전 안전성을 확인한다 | `docs/checklists/pre-apply.md` |
| drift 나 state 문제를 본다 | `docs/runbooks/*.md` |
| 실제 apply를 한다 | `ops/README.md` |

---

## 저장소 구조를 읽는 방법

| 영역 | 의미 |
|------|------|
| `ops/bootstrap/` | remote state S3/DynamoDB를 최초로 만드는 코드 |
| `ops/dev/` | dev 환경 Terragrunt 호출부 |
| `ops/prod/` | prod 환경 Terragrunt 호출부 |
| `ops/_envs/` | 공통 변수 참조와 환경별 기준값 |
| `ops/legacy/` | 재사용 모듈과 모듈별 README |
| `docs/` | 읽는 순서, 규칙, 체크리스트, 런북, 템플릿 |

---

## 모듈 분류

| 분류 | 대표 모듈 | 읽어야 할 포인트 |
|------|-----------|-----------------|
| 네트워크 | `vpc`, `alb`, `route53`, `cloudfront`, `waf`, `tgw` | CIDR, DNS, 엣지 정책, 연결 순서 |
| 컴퓨트 | `ec2`, `eks`, `bastion` | 인스턴스/노드 수명, 접근 경로, 배포 순서 |
| 데이터 | `rds`, `elasticache`, `dynamodb`, `s3`, `backup` | 보호 옵션, 보존 정책, 암호화 |
| 보안 | `iam`, `kms`, `secrets-manager`, `guardduty` | 최소 권한, 키/시크릿/감사 |
| 관측/배포 | `cloudwatch`, `ecr`, `codepipeline` | 알람, 이미지 저장소, CI/CD 흐름 |

---

## 새 모듈을 만들 때

### 1. 먼저 문서를 만든다

- 모듈 목적과 생성 리소스를 적는다.
- dev/prod 차이를 표로 적는다.
- 삭제 조건과 주의사항을 적는다.
- 관련 runbook과 checklist를 연결한다.

### 2. 그 다음 코드 경계를 정한다

- 재사용 가능한 리소스는 `ops/legacy/<module>/modules/<module>/`에 둔다.
- 환경별 호출부는 `ops/legacy/<module>/envs/dev`, `ops/legacy/<module>/envs/prod`에 둔다.
- Terragrunt 경로는 `ops/dev/<module>/terragrunt.hcl`, `ops/prod/<module>/terragrunt.hcl`에 둔다.

### 3. 마지막에 검증한다

- `terraform fmt` 또는 `terragrunt hclfmt`
- `terraform validate` 또는 `terragrunt validate`
- `plan` 결과 검토
- `docs/checklists/pre-apply.md` 확인

---

## 작업 패턴

### 기존 모듈을 고칠 때

1. `ops/legacy/<module>/README.md`를 본다.
2. `variables.tf`, `outputs.tf`, `main.tf`를 확인한다.
3. `ops/dev/<module>`와 `ops/prod/<module>`의 입력값 차이를 본다.
4. 문서가 바뀌면 `README.md`, `CLAUDE.md`, `docs/README.md`도 같이 갱신한다.

### 환경별 차이를 넣을 때

다음 기준을 우선 적용한다.

| 항목 | dev | prod |
|------|-----|------|
| 삭제 보호 | 느슨함 | 강함 |
| 백업/보존 | 짧음 | 길게 |
| 알람 | 최소 | 활성화 |
| 암호화 | 선택적 | 필수 |
| `prevent_destroy` | 보통 없음 | 필수 |

### state를 가져올 때

1. 실제 리소스 ID를 확인한다.
2. 코드와 리소스 이름을 맞춘다.
3. `docs/runbooks/state-import.md` 절차를 따른다.

---

## Terragrunt를 이해하는 기준

| 개념 | 의미 |
|------|------|
| `bootstrap` | remote state를 만들기 위한 1회성 코드 |
| `live config` | `ops/dev`, `ops/prod`의 환경별 실행 구성 |
| `run-all` | 의존성을 보고 순차적으로 plan/apply하는 방식 |
| `mock_outputs` | 아직 없는 의존성도 plan 단계에서 참조하게 하는 장치 |

---

## 읽는 순서

1. `docs/README.md`
2. `docs/getting-started.md`
3. `docs/module-build-guide.md`
4. `docs/rules/README.md`
5. `docs/checklists/README.md`
6. `docs/runbooks/README.md`
7. `ops/README.md`

