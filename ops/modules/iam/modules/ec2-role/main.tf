###############################################################################
### EC2 인스턴스 IAM Role 모듈
### - SSM Session Manager 원격 접속
### - CloudWatch 메트릭/로그 전송
### - S3 버킷 접근 (선택)
###############################################################################

### AssumeRole 정책 문서 (EC2 서비스)
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

### IAM Role 생성
resource "aws_iam_role" "ec2_role" {
  name               = "${var.project_name}-${var.environment}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ec2-role"
  })
}

### EC2 Instance Profile 생성
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-ec2-profile"
  })
}

### 관리형 정책 연결: SSM Session Manager 원격 접속
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

### 관리형 정책 연결: CloudWatch 메트릭/로그 전송
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

### 인라인 정책: S3 버킷 접근 (버킷 ARN이 지정된 경우에만 생성)
data "aws_iam_policy_document" "s3_access" {
  count = length(var.s3_bucket_arns) > 0 ? 1 : 0

  statement {
    sid    = "S3BucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = var.s3_bucket_arns
  }
}

resource "aws_iam_role_policy" "s3_access" {
  count  = length(var.s3_bucket_arns) > 0 ? 1 : 0
  name   = "${var.project_name}-${var.environment}-ec2-s3-policy"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.s3_access[0].json
}
