### =============================================================================
### dev/bastion/terragrunt.hcl
### DEV 환경 Bastion Host (점프 서버)
###
### 역할: 프라이빗 서브넷의 RDS, ElastiCache 등에 접근하기 위한 점프 서버
###       SSH 대신 AWS SSM Session Manager 사용 (키 파일 불필요, 보안 강화)
### DEV 특징:
###   - SSM Session Manager 방식 (enable_ssh = false)
###     → 보안 그룹에 SSH 포트(22) 불필요
###     → 키 파일 없이 aws ssm start-session 명령어로 접속
###   - create_eip = false: Elastic IP 불필요
###   - instance_type = t3.micro: 최소 사양
### SSM 접속 방법:
###   aws ssm start-session --target {instance_id}
### 의존성: vpc
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id            = "vpc-00000000000000000"
    public_subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
    vpc_cidr_block    = "10.10.0.0/16"
  }
}

terraform {
  source = "../../bastion/modules/bastion"
}

inputs = {
  # ---------------------------------------------------------------
  # 네트워크 — VPC 출력값 참조
  # Bastion은 퍼블릭 서브넷에 배포 (SSM은 인터넷 경유)
  # VPC Endpoint(ssm, ssmmessages, ec2messages) 구성 시 프라이빗 서브넷도 가능
  # ---------------------------------------------------------------
  vpc_id    = dependency.vpc.outputs.vpc_id
  subnet_id = dependency.vpc.outputs.public_subnet_ids[0]

  # ---------------------------------------------------------------
  # AMI 설정
  # SSM Agent가 사전 설치된 Amazon Linux 2023 사용 권장
  # 최신 AMI ID 확인:
  #   aws ec2 describe-images --owners amazon \
  #     --filters "Name=name,Values=al2023-ami-*" \
  #     --query "Images | sort_by(@, &CreationDate) | [-1].ImageId"
  # ---------------------------------------------------------------
  ami_id = "ami-0c9c942bd7bf113a2" # Amazon Linux 2023 (서울, 플레이스홀더)

  # ---------------------------------------------------------------
  # 인스턴스 사양
  # Bastion은 트래픽 전달만 하므로 t3.micro로 충분
  # ---------------------------------------------------------------
  instance_type = "t3.micro"

  # ---------------------------------------------------------------
  # SSH 설정
  # enable_ssh = false: SSH 포트 비활성화 (SSM 전용)
  # SSM 방식의 장점:
  #   - SSH 키 파일 관리 불필요
  #   - 22번 포트 오픈 불필요 (공격 표면 감소)
  #   - CloudTrail에 접속 이력 자동 기록
  # ---------------------------------------------------------------
  enable_ssh = false

  # ---------------------------------------------------------------
  # Elastic IP
  # dev: false (SSM 접속은 IP 무관, 비용 절약)
  # prod: false (동일 — SSM이면 고정 IP 불필요)
  # ---------------------------------------------------------------
  create_eip = false
}
