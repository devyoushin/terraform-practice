### =============================================================================
### prod/ec2/terragrunt.hcl
### PROD 환경 EC2 — 애플리케이션 서버
###
### 역할: 프라이빗 서브넷에 배치된 애플리케이션 서버
### PROD 특징:
###   - associate_public_ip = false  (프라이빗 서브넷 — 직접 인터넷 노출 없음)
###   - enable_detailed_monitoring = true  (1분 단위 상세 메트릭)
###   - instance_type = "t3.medium"  (dev: t3.micro)
###   - SSH 직접 접근 차단 — SSM Session Manager 또는 Bastion 경유만 허용
###   - create_eip = true  (필요 시 EIP 연결 — 퍼블릭 서브넷 배치 시)
###
### 의존성:
###   - vpc → 서브넷 ID, 보안 그룹 설정
###   - iam → EC2 인스턴스 프로파일 (SSM 접근 권한)
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ AMI ID는 최신 Amazon Linux 2 / AL2023 ARN으로 교체 필요
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    private_subnet_ids = ["subnet-00000000000000000", "subnet-11111111111111111", "subnet-22222222222222222"]
    vpc_cidr_block     = "10.0.0.0/16"
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
  source = "../../ec2/modules/ec2"
}

inputs = {
  # ---------------------------------------------------------------
  # 인스턴스 스펙
  # prod: t3.medium — 안정적인 CPU/메모리 성능
  # dev:  t3.micro  — 비용 최소화
  #
  # 프로덕션 부하에 따라 t3.large 또는 m5 계열로 업그레이드 고려
  # ---------------------------------------------------------------
  instance_type = "t3.medium"

  # ---------------------------------------------------------------
  # AMI
  # ⚠️ 최신 Amazon Linux 2023 AMI ID로 교체 필요!
  # 확인 방법:
  #   aws ec2 describe-images \
  #     --owners amazon \
  #     --filters "Name=name,Values=al2023-ami-*-x86_64" \
  #     --query "sort_by(Images,&CreationDate)[-1].ImageId"
  # ---------------------------------------------------------------
  ami_id = "REPLACE_WITH_LATEST_AL2023_AMI_ID"

  # ---------------------------------------------------------------
  # 네트워크 배치
  # prod: 프라이빗 서브넷 (인터넷 직접 노출 없음)
  # 외부 트래픽은 ALB → EC2 (프라이빗) 경로만 허용
  # ---------------------------------------------------------------
  subnet_id            = dependency.vpc.outputs.private_subnet_ids[0]
  vpc_id               = dependency.vpc.outputs.vpc_id
  associate_public_ip  = false

  # ---------------------------------------------------------------
  # 상세 모니터링
  # prod: true  — 1분 단위 CloudWatch 메트릭 수집
  # dev:  false — 5분 단위 기본 메트릭 (비용 절약)
  # ---------------------------------------------------------------
  enable_detailed_monitoring = true

  # ---------------------------------------------------------------
  # EIP (Elastic IP)
  # prod: true — 고정 IP 필요 시 활성화 (퍼블릭 서브넷 배치 인스턴스용)
  # 프라이빗 서브넷 배치 시 EIP 불필요 → false 로 설정
  # ---------------------------------------------------------------
  create_eip = false

  # ---------------------------------------------------------------
  # IAM 인스턴스 프로파일
  # SSM Session Manager 접근, CloudWatch 로그 전송 권한 포함
  # ---------------------------------------------------------------
  iam_instance_profile = dependency.iam.outputs.instance_profile_name

  # ---------------------------------------------------------------
  # 보안 그룹 설정
  # prod: SSH(22) 포트 개방 금지 — SSM 또는 Bastion 경유 접근
  # Bastion 보안 그룹에서만 SSH 허용하는 경우 bastion SG ID 지정
  # ---------------------------------------------------------------
  enable_ssh_from_anywhere = false
  vpc_cidr_block           = dependency.vpc.outputs.vpc_cidr_block

  # ---------------------------------------------------------------
  # 루트 볼륨 설정
  # prod: 암호화 활성화, 충분한 용량
  # ---------------------------------------------------------------
  root_volume_size      = 30
  root_volume_type      = "gp3"
  root_volume_encrypted = true
}
