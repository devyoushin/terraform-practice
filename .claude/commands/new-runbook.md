새 Terraform 운영 런북을 생성합니다.

**사용법**: `/new-runbook <작업명>`

**예시**: `/new-runbook RDS 스냅샷 복구`

다음 단계를 수행하세요:

1. `templates/runbook.md`를 읽어 템플릿 구조를 확인하세요.
2. 작업 유형을 분류하세요:
   - `인프라 변경`: 모듈 추가/수정/삭제
   - `환경 배포`: dev/prod 배포 절차
   - `긴급 대응`: 인프라 장애 대응
   - `상태 관리`: tfstate 마이그레이션, import
3. `<모듈명>/runbooks/<작업명>.md`를 생성하세요:
   - 사전 체크리스트 (prod 보호 확인, 플랜 검토 의무 등)
   - 환경 변수 설정 (AWS_PROFILE, ENV)
   - Step별 terraform 명령어 (`-target` 옵션 포함)
   - 성공 기준 체크리스트
   - 롤백 절차 (terraform plan -target으로 개별 복구)
   - 모니터링 포인트 (CloudWatch 지표)
