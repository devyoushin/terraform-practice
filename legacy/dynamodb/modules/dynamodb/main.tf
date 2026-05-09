### =============================================================================
### modules/dynamodb/main.tf
### AWS DynamoDB 테이블을 생성하는 재사용 가능한 모듈
### =============================================================================

locals {
  table_name = var.table_name != null ? var.table_name : "${var.project_name}-${var.environment}-${var.table_suffix}"
  tags = merge(var.common_tags, {
    Module      = "dynamodb"
    Environment = var.environment
  })
}

### -----------------------------------------------------------------------------
### 1. DynamoDB 테이블
### -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "this" {
  name         = local.table_name
  billing_mode = var.billing_mode

  # PROVISIONED 모드에서만 용량 지정
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  hash_key  = var.hash_key
  range_key = var.range_key != "" ? var.range_key : null

  # 실수로 인한 테이블 삭제 방지 (prod 환경 권장)
  deletion_protection_enabled = var.deletion_protection

  # DynamoDB Streams 활성화 (Lambda 트리거, 변경 이벤트 처리 등)
  stream_enabled   = var.enable_stream
  stream_view_type = var.enable_stream ? var.stream_view_type : null

  # Point-in-Time Recovery: 35일 이내 임의 시점으로 복구 가능
  point_in_time_recovery {
    enabled = var.enable_pitr
  }

  # 서버 사이드 암호화 (항상 활성화)
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  # TTL: 특정 시간이 지난 항목 자동 삭제 (세션, 캐시 등)
  ttl {
    attribute_name = var.ttl_attribute
    enabled        = var.ttl_attribute != ""
  }

  # 테이블 속성 정의 (키 및 GSI에 사용되는 속성만 정의)
  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Global Secondary Index 정의
  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = lookup(global_secondary_index.value, "range_key", null)
      projection_type = global_secondary_index.value.projection_type
      read_capacity   = var.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "read_capacity", 5) : null
      write_capacity  = var.billing_mode == "PROVISIONED" ? lookup(global_secondary_index.value, "write_capacity", 5) : null
      non_key_attributes = global_secondary_index.value.projection_type == "INCLUDE" ? lookup(global_secondary_index.value, "non_key_attributes", []) : null
    }
  }

  tags = local.tags
}

### -----------------------------------------------------------------------------
### 2. Auto Scaling (PROVISIONED 모드 + enable_autoscaling = true 일 때만)
### -----------------------------------------------------------------------------

# 읽기 용량 자동 스케일링 타겟
resource "aws_appautoscaling_target" "read_target" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_read_max
  min_capacity       = var.autoscaling_read_min
  resource_id        = "table/${aws_dynamodb_table.this.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

# 읽기 용량 자동 스케일링 정책
resource "aws_appautoscaling_policy" "read_policy" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  name               = "${local.table_name}-read-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.read_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.read_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = var.autoscaling_read_target
  }
}

# 쓰기 용량 자동 스케일링 타겟
resource "aws_appautoscaling_target" "write_target" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_write_max
  min_capacity       = var.autoscaling_write_min
  resource_id        = "table/${aws_dynamodb_table.this.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

# 쓰기 용량 자동 스케일링 정책
resource "aws_appautoscaling_policy" "write_policy" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  name               = "${local.table_name}-write-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.write_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.write_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = var.autoscaling_write_target
  }
}
