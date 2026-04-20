terraform-practice 지식베이스에서 관련 내용을 검색합니다.

**사용법**: `/search-kb <검색어>`

**예시**: `/search-kb EKS Karpenter 배포 순서`

다음 단계를 수행하세요:

1. 검색어와 관련된 모듈 디렉토리를 파악하세요:
   - 컴퓨팅: `ec2/`, `eks/`, `ecr/`
   - 네트워크: `vpc/`, `alb/`, `tgw/`, `route53/`
   - 데이터: `rds/`, `dynamodb/`, `elasticache/`, `s3/`
   - 보안: `iam/`, `kms/`, `secrets-manager/`, `waf/`, `guardduty/`
   - 운영: `cloudwatch/`, `backup/`, `codepipeline/`

2. 관련 모듈의 README.md와 modules/main.tf를 읽어 답변을 구성하세요.

3. CLAUDE.md의 관련 규칙(환경별 설정 원칙, 주의사항 등)도 함께 참조하세요.

4. 결과를 다음 형식으로 제시하세요:
   - **관련 모듈**: 파일 경로
   - **핵심 내용**: 검색어와 관련된 설명
   - **예시 코드**: 관련 HCL 또는 CLI 명령어
   - **주의사항**: 알려진 이슈 또는 함정
