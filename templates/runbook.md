# Runbook: {작업명}

> **분류**: {인프라 변경 | 환경 배포 | 긴급 대응 | 상태 관리}
> **대상 모듈**: {모듈명}
> **영향 환경**: {dev | prod | 전체}
> **작성일**: {YYYY-MM-DD}
> **예상 소요 시간**: {N분}
> **영향 범위**: {무중단 | 서비스 영향 있음}

---

## 사전 체크리스트

- [ ] AWS 프로필 확인 (`aws sts get-caller-identity`)
- [ ] 현재 tfstate 백업 (S3 버전 확인)
- [ ] prod 환경: 플랜 파일 저장 의무 (`-out=tfplan.binary`)
- [ ] prod 환경: `prevent_destroy` 리소스 목록 파악
- [ ] 롤백 방법 확인
- [ ] 변경 영향 범위 파악

---

## 환경 변수 설정

```bash
export AWS_PROFILE=<PROFILE>
export AWS_DEFAULT_REGION=ap-northeast-2
export ENV=<dev|prod>
export MODULE=<모듈명>
```

---

## Step 1: 사전 상태 확인

```bash
# 현재 계정 확인
aws sts get-caller-identity

# Terraform 상태 확인
cd $MODULE
make output ENV=$ENV
```

---

## Step 2: {작업 내용}

```bash
make plan ENV=$ENV
```

```hcl
# 변경할 Terraform 코드
{변경 내용}
```

---

## Step 3: 적용

```bash
# prod는 플랜 파일 저장 후 적용
terraform plan -out=tfplan.binary
terraform show -no-color tfplan.binary > tfplan.txt
grep "will be destroyed" tfplan.txt  # 삭제 리소스 반드시 확인

# 검토 완료 후 적용
terraform apply tfplan.binary
```

---

## Step 4: 완료 확인

```bash
{확인 명령어}
```

**성공 기준**:
- [ ] {조건 1}
- [ ] {조건 2}

---

## 롤백 절차

```bash
# 특정 리소스만 이전 상태로
terraform plan -target={resource.name}
terraform apply -target={resource.name}

# 또는 tfstate 이전 버전 복구 (S3)
aws s3api get-object-attributes --bucket <BUCKET> --key <KEY> --object-attributes Checksum
```

---

## 모니터링 포인트

| 지표 | 확인 방법 | 정상 기준 |
|------|---------|---------|
| {지표} | CloudWatch / AWS Console | {기준} |
