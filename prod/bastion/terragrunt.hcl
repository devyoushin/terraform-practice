### =============================================================================
### prod/bastion/terragrunt.hcl
### PROD 환경 Bastion Host — 점프 서버
###
### 역할: 프라이빗 서브넷의 리소스(EC2, RDS 등)에 안전하게 접근하는 점프 서버
###   - SSH 직접 접근 대신 SSM Session Manager 권장
###   - 퍼블릭 서브넷에 배치하여 외부에서 접근 가능
###   - RDS, ElastiCache 포트 포워딩에 활용
###
### PROD 특징:
###   - instance_type = "t3.micro"   (소형 — Bastion은 고사양 불필요)
###   - enable_ssh = false            (SSM만 허용 — SSH 포트 차단)
###   - create_eip = false            (NAT Gateway 통해 접근)
###
### 의존성:
###   - vpc → 퍼블릭 서브넷 ID
###   - iam → EC2 인스턴스 프로파일 (SSM 권한)
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ SSH 포트(22) 개방 금지 — SSM Session Manager만 사용
###    SSM 접근 방법:
###      aws ssm start-session --target <instance-id>
###      aws ssm start-session --target <instance-id> \
###        --document-name AWS-StartPortForwardingSessionToRemoteHost \
###        --parameters '{"host":["<rds-endpoint>"],"portNumber":["5432"],"localPortNumber":["5432"]}'
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id            = "vpc-00000000000000000"
    public_subnet_ids = ["subnet-00000000000000000", "subnet-11111111111111111", "subnet-22222222222222222"]
    vpc_cidr_block    = "10.0.0.0/16"
  }
}

dependency "iam" {
  config_path = "../iam"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    instance_profile_name = "terraform-practice-prod-ec2-profile"
    instance_profile_arn  = "arn:aws:iam::123456789012:instance-profile/terraform-practice-prod-ec2-profile"
  }
}

terraform {
  source = "../../bastion/modules/bastion"
}

inputs = {
  # ---------------------------------------------------------------
  # 네트워크 배치
  # Bastion은 퍼블릭 서브넷에 배치 (외부 → Bastion → 내부 접근)
  # ---------------------------------------------------------------
  vpc_id    = dependency.vpc.outputs.vpc_id
  subnet_id = dependency.vpc.outputs.public_subnet_ids[0]

  # ---------------------------------------------------------------
  # 인스턴스 스펙
  # Bastion은 트래픽 처리용이 아닌 접근 경로 제공 목적
  # t3.micro로 충분 — 비용 최소화
  # ---------------------------------------------------------------
  instance_type = "t3.micro"

  # ---------------------------------------------------------------
  # AMI
  # ⚠️ 최신 Amazon Linux 2023 AMI ID로 교체 필요!
  # ---------------------------------------------------------------
  ami_id = "REPLACE_WITH_LATEST_AL2023_AMI_ID"

  # ---------------------------------------------------------------
  # SSH 접근 비활성화
  # prod: false — SSH 포트(22) 완전 차단
  #              SSM Session Manager를 통한 접근만 허용
  #
  # SSM 접근 전제 조건:
  #   1. IAM 인스턴스 프로파일에 AmazonSSMManagedInstanceCore 정책
  #   2. SSM Agent 설치 (Amazon Linux 2023 기본 포함)
  #   3. 인터넷 또는 VPC 엔드포인트를 통한 SSM 연결
  # ---------------------------------------------------------------
  enable_ssh = false

  # ---------------------------------------------------------------
  # EIP (Elastic IP)
  # prod: false — 고정 IP 불필요 (SSM은 IP 불필요)
  #               SSH 허용 시에는 EIP 할당으로 고정 IP 사용 권장
  # ---------------------------------------------------------------
  create_eip = false

  # ---------------------------------------------------------------
  # IAM 인스턴스 프로파일
  # SSM Session Manager 접근 권한 포함
  # ---------------------------------------------------------------
  iam_instance_profile = dependency.iam.outputs.instance_profile_name

  # ---------------------------------------------------------------
  # 루트 볼륨
  # Bastion은 스토리지 집약적 작업 없으므로 소용량으로 충분
  # ---------------------------------------------------------------
  root_volume_size      = 20
  root_volume_type      = "gp3"
  root_volume_encrypted = true
}
