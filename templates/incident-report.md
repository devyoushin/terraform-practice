# 장애 보고서: {장애명}

> **발생 일시**: {YYYY-MM-DD HH:MM} KST
> **해결 일시**: {YYYY-MM-DD HH:MM} KST
> **유형**: {인프라 장애 | Terraform 상태 불일치 | 보안 이벤트 | 비용 이상}
> **영향 모듈**: {모듈명}
> **영향 환경**: {dev | prod}

---

## 1. 요약

{장애 원인과 해결 방법을 3문장 이내로 요약. Terraform 관점에서 무엇이 잘못되었고 어떻게 고쳤는지}

---

## 2. 타임라인

| 시각 | 이벤트 | 감지 방법 |
|------|--------|---------|
| HH:MM | 장애 시작 | CloudWatch / 알람 |
| HH:MM | 원인 파악 | terraform plan / CloudTrail |
| HH:MM | 해결 완료 | - |

---

## 3. 근본 원인

**관련 모듈**: `{모듈명}/modules/{모듈명}/main.tf`

```bash
# 원인 확인에 사용한 명령어
terraform plan
aws cloudtrail lookup-events ...
```

{기술적 근본 원인 설명}

---

## 4. 해결 방법

```bash
{해결 명령어}
```

```hcl
# Terraform 수정 내용
{변경 내용}
```

---

## 5. 재발 방지

| 대책 | 관련 파일 | 완료 기한 |
|------|----------|---------|
| {대책} | {rules/ 또는 모듈 파일} | {날짜} |

---

## 6. 아키텍처 개선사항

- {개선 1}: `{관련 모듈}` 수정 필요
- {개선 2}: `rules/terraform-conventions.md` 업데이트 필요
