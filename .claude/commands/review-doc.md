Terraform 모듈 문서 또는 코드를 검토합니다.

**사용법**: `/review-doc <파일 경로>`

**예시**: `/review-doc eks/modules/eks/main.tf`

다음 기준으로 검토하세요:

**코드 품질 (rules/terraform-conventions.md 기준)**
- [ ] `### ===` 헤더 주석과 `### ---` 섹션 구분자 사용 여부
- [ ] `project_name`, `environment`(validation 포함), `common_tags` 변수 존재 여부
- [ ] 리소스 명명 규칙: `{project_name}-{environment}-{resource_type}`
- [ ] 공통 태그 패턴 적용 여부

**환경별 설정 (CLAUDE.md 환경별 설정 원칙 기준)**
- [ ] dev: `force_destroy = true`, `deletion_protection = false`
- [ ] prod: `prevent_destroy`, `deletion_protection = true`, KMS 암호화 필수

**보안 (rules/security-checklist.md 기준)**
- [ ] 최소 권한 IAM 정책
- [ ] 퍼블릭 접근 차단 설정
- [ ] 암호화 활성화 여부

**문서 품질**
- [ ] README가 EKS README 스타일을 따르는지
- [ ] `terraform.tfvars.example` 존재 여부
- [ ] 모든 변수에 `description` 존재 여부

검토 결과를 항목별로 정리하고 개선이 필요한 부분에 구체적인 수정 방법을 제시하세요.
