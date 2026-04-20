Terraform 트러블슈팅 케이스를 추가합니다.

**사용법**: `/add-troubleshooting <증상 설명>`

**예시**: `/add-troubleshooting EKS 노드 그룹 업데이트 타임아웃`

다음 단계를 수행하세요:

1. 관련 모듈의 `README.md`를 읽어 기존 트러블슈팅 섹션을 확인하세요.
2. 아래 형식으로 트러블슈팅 케이스를 작성하세요:

```markdown
### <증상>

**원인**: <근본 원인>

**확인 방법**:
\`\`\`bash
terraform plan -target=<resource>
aws <service> describe-...
\`\`\`

**해결**:
\`\`\`bash
<해결 명령어>
\`\`\`

**예방**: <재발 방지 방법>
```

3. 해당 모듈 README.md의 트러블슈팅 섹션에 추가하세요.
4. 동일한 내용이 여러 모듈에 적용된다면 `rules/terraform-conventions.md`에도 주의사항으로 추가하세요.
