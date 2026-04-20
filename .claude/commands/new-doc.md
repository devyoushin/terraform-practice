새 Terraform 모듈 문서를 생성합니다.

**사용법**: `/new-doc <모듈명>`

**예시**: `/new-doc elasticsearchstorage`

다음 단계를 수행하세요:

1. `templates/service-doc.md`를 읽어 템플릿 구조를 확인하세요.
2. 아래 카테고리에서 적절한 위치를 결정하세요:
   - 컴퓨팅: ec2, eks, ecr
   - 네트워크: vpc, alb, tgw, route53
   - 데이터: rds, dynamodb, elasticache, s3
   - 보안: iam, kms, secrets-manager, waf, guardduty
   - 운영: cloudwatch, backup, codepipeline
3. `<모듈명>/README.md`를 템플릿 기반으로 생성하세요:
   - 레이어, 관련 AWS 서비스, 작성일 메타데이터 포함
   - modules/envs 디렉토리 구조 다이어그램
   - Terraform 핵심 리소스 코드 예시
   - 환경별 설정 차이 (dev vs prod)
   - Makefile 사용법
   - 트러블슈팅 섹션
   - 구현 체크리스트 (rules/terraform-conventions.md 기준)
