# 보안 체크리스트 — terraform-practice

## IAM

- [ ] 와일드카드 Action(`*`) 사용 최소화 — 서비스 수준으로 범위 제한
- [ ] Resource `*` 대신 특정 ARN 지정
- [ ] 역할 신뢰 정책: 필요한 서비스/계정만 허용
- [ ] 인라인 정책보다 관리형 정책 선호
- [ ] 미사용 IAM 역할/정책 정기 감사

## 네트워크

- [ ] 보안 그룹 `0.0.0.0/0` ingress 허용 금지 (필요 시 명시적 승인)
- [ ] 퍼블릭 서브넷에는 ALB/NAT Gateway만 배치
- [ ] RDS, ElastiCache, EKS 노드는 프라이빗 서브넷 전용
- [ ] VPC Flow Log 활성화
- [ ] NACLs로 서브넷 수준 방어

## 데이터 보호

- [ ] S3: `block_public_acls = true`, `block_public_policy = true`
- [ ] S3: 서버 사이드 암호화 (SSE-S3 최소, 민감 데이터는 SSE-KMS)
- [ ] RDS: `storage_encrypted = true`, KMS 키 지정
- [ ] EKS secrets: KMS 봉투 암호화
- [ ] ElastiCache: `at_rest_encryption_enabled`, `transit_encryption_enabled`

## 비밀 관리

- [ ] 하드코딩된 비밀번호/액세스 키 금지
- [ ] 민감 변수는 `sensitive = true` 설정
- [ ] 비밀번호는 Secrets Manager 또는 SSM Parameter Store
- [ ] `*.tfvars` gitignore 적용, `*.tfvars.example`만 커밋

## 모니터링 및 감사

- [ ] CloudTrail 활성화 (모든 리전)
- [ ] GuardDuty 활성화
- [ ] Config Rules로 규정 준수 모니터링
- [ ] prod 환경 CloudWatch 알람 필수

## prod 적용 전 필수

```bash
# 플랜 검토 (삭제 리소스 반드시 확인)
terraform plan -out=tfplan.binary
terraform show -no-color tfplan.binary > tfplan.txt
grep "will be destroyed" tfplan.txt
```
