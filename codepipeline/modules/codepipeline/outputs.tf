### ============================================================
### modules/codepipeline/outputs.tf
### CodePipeline 모듈 출력값 정의
### ============================================================

### 파이프라인 정보

output "pipeline_arn" {
  description = "CodePipeline ARN"
  value       = aws_codepipeline.this.arn
}

output "pipeline_name" {
  description = "CodePipeline 이름"
  value       = aws_codepipeline.this.name
}

### CodeBuild 정보

output "codebuild_project_name" {
  description = "CodeBuild 프로젝트 이름"
  value       = aws_codebuild_project.this.name
}

output "codebuild_project_arn" {
  description = "CodeBuild 프로젝트 ARN"
  value       = aws_codebuild_project.this.arn
}

### S3 아티팩트 버킷 정보

output "artifact_bucket_name" {
  description = "아티팩트 S3 버킷 이름"
  value       = aws_s3_bucket.artifact.bucket
}

output "artifact_bucket_arn" {
  description = "아티팩트 S3 버킷 ARN"
  value       = aws_s3_bucket.artifact.arn
}

### IAM 역할 정보

output "pipeline_role_arn" {
  description = "CodePipeline IAM 역할 ARN"
  value       = aws_iam_role.pipeline_role.arn
}

output "codebuild_role_arn" {
  description = "CodeBuild IAM 역할 ARN"
  value       = aws_iam_role.codebuild_role.arn
}

### CloudWatch 로그 정보

output "codebuild_log_group_name" {
  description = "CodeBuild 빌드 로그 CloudWatch 로그 그룹 이름"
  value       = aws_cloudwatch_log_group.codebuild.name
}
