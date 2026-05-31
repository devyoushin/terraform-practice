# 모니터링 지침 — terraform-practice

## CloudWatch 알람 필수 항목 (prod)

| 서비스 | 지표 | 임계치 |
|--------|------|--------|
| EC2 | CPUUtilization | > 80% (5분) |
| RDS | CPUUtilization | > 80% |
| RDS | FreeStorageSpace | < 10GB |
| RDS | DatabaseConnections | > 최대 연결 수의 80% |
| ElastiCache | CPUUtilization | > 75% |
| ElastiCache | FreeableMemory | < 100MB |
| ALB | TargetResponseTime | > 1초 |
| ALB | UnHealthyHostCount | > 0 |
| EKS | node_cpu_utilization | > 80% |

## Terraform 알람 리소스 패턴

```hcl
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU 사용률이 80%를 초과했습니다"
  alarm_actions       = [var.sns_alarm_topic_arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.this.id
  }

  tags = var.common_tags
}
```

## 비용 모니터링

- AWS Budgets로 월별 예산 경고 설정 (80%, 100%)
- Cost Explorer 태그 기반 비용 배분 (Project, Environment 태그)
- dev 환경 비용이 prod의 30% 초과 시 리소스 검토

## Terraform 상태 모니터링

```bash
# 드리프트 감지 (주기적 실행 권장)
terraform plan -detailed-exitcode
# exit code 2 = 변경사항 있음 (드리프트)

# 상태 파일 잠금 확인
aws dynamodb scan --table-name terraform-locks
```

## 알람 SNS 토픽 패턴

prod 환경의 모든 CloudWatch 알람은 반드시 SNS 토픽을 통해 Slack/이메일 알림 연동:

```hcl
variable "sns_alarm_topic_arn" {
  description = "CloudWatch 알람 수신 SNS 토픽 ARN"
  type        = string
}
```
