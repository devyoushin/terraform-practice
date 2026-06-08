# Terraform 시작 가이드

이 저장소는 `Terraform` 단독 예제가 아니라, `Terragrunt`를 중심으로 한 실전 인프라 구성 저장소다.

처음에는 전체 모듈을 외우려 하지 말고, 아래 순서로 읽는 것이 빠르다.

## 1. 먼저 상황을 고른다

| 작업 | 먼저 볼 문서 |
|------|--------------|
| 이 저장소 구조를 처음 이해한다 | `docs/README.md` |
| 새 모듈을 만들거나 기존 모듈을 고친다 | `module-build-guide.md` |
| 실제 적용 전에 점검한다 | `checklists/pre-apply.md` |
| 모듈 구조를 리뷰한다 | `checklists/module-review.md` |
| 예상치 못한 drift를 확인한다 | `runbooks/drift-detection.md` |
| 이미 존재하는 리소스를 state에 넣는다 | `runbooks/state-import.md` |
| 문서/코드 규칙을 확인한다 | `rules/README.md` |
| AI 작업 지침을 확인한다 | `agents/README.md` |
| 실제 실행 방법을 본다 | `../ops/README.md` |

## 2. 이 저장소를 읽는 순서

1. `docs/README.md`
2. `docs/getting-started.md`
3. `docs/module-build-guide.md`
4. `docs/rules/README.md`
5. `docs/checklists/README.md`
6. `docs/runbooks/README.md`
7. `../ops/README.md`

## 3. 실제 작업 순서

### 처음 세팅할 때

```bash
brew install terraform terragrunt
terraform version
terragrunt --version
```

```bash
cd ops/bootstrap
terraform init
terraform apply
```

### 새 모듈을 볼 때

1. `docs/module-build-guide.md`에서 모듈 종류와 배포 흐름을 확인한다.
2. 해당 모듈의 `ops/modules/<module>/README.md`를 읽는다.
3. `ops/live/nonprod/ap-northeast-2/dev/<module>/terragrunt.hcl`과 `ops/live/prod/ap-northeast-2/prod/<module>/terragrunt.hcl`을 확인한다.
4. `docs/checklists/pre-apply.md`를 읽고 plan을 만든다.
5. prod 반영 전에는 `terraform plan` 결과를 저장하고 검토한다.

### 기존 리소스를 편입할 때

1. `docs/runbooks/state-import.md`를 먼저 읽는다.
2. 코드와 실제 AWS 리소스가 같은지 확인한다.
3. import 후 `terragrunt plan`으로 차이를 정리한다.

## 4. 기본 실행 명령

```bash
cd ops/live/nonprod/ap-northeast-2/dev/vpc
terragrunt init
terragrunt plan
terragrunt apply
```

```bash
terragrunt run-all plan --terragrunt-working-dir ops/live/nonprod/ap-northeast-2/dev
terragrunt run-all apply --terragrunt-working-dir ops/live/nonprod/ap-northeast-2/dev
```

## 5. 헷갈릴 때 보는 문서

| 증상 | 문서 |
|------|------|
| 모듈이 어떻게 나뉘는지 모르겠다 | `module-build-guide.md` |
| plan 결과가 위험한지 모르겠다 | `checklists/pre-apply.md` |
| state와 실제 리소스가 어긋난 것 같다 | `runbooks/drift-detection.md` |
| 기존 리소스를 Terraform으로 가져와야 한다 | `runbooks/state-import.md` |
| 문서 작성 기준이 필요하다 | `rules/doc-writing.md` |

