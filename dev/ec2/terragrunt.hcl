### =============================================================================
### dev/ec2/terragrunt.hcl
### DEV 환경 EC2 인스턴스
###
### 역할: 개발 및 테스트용 EC2 인스턴스
###       애플리케이션 서버 또는 개발자 작업 서버로 활용
### DEV 특징:
###   - associate_public_ip = true (퍼블릭 서브넷 배포, 직접 접근 가능)
###   - create_eip = false (Elastic IP 불필요, 재시작 시 IP 변경 허용)
###   - enable_detailed_monitoring = false (비용 절약)
###   - 기본 인스턴스 타입: t3.micro (dev 최소 사양)
### 의존성: vpc
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"

  # plan/validate 시 실제 VPC가 없어도 동작하도록 mock 값 제공
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id             = "vpc-00000000000000000"
    public_subnet_ids  = ["subnet-00000000000000001", "subnet-00000000000000002"]
    private_subnet_ids = ["subnet-11111111111111111", "subnet-11111111111111112"]
    vpc_cidr_block     = "10.10.0.0/16"
  }
}

terraform {
  source = "../../ec2/modules/ec2"
}

inputs = {
  # ---------------------------------------------------------------
  # 네트워크 — VPC 출력값 참조
  # dev: 퍼블릭 서브넷 배포 (개발 편의상 직접 접근)
  # prod: 프라이빗 서브넷 배포 (ALB/Bastion 경유 접근)
  # ---------------------------------------------------------------
  vpc_id    = dependency.vpc.outputs.vpc_id
  subnet_id = dependency.vpc.outputs.public_subnet_ids[0]

  # 퍼블릭 IP 자동 할당 (dev: true, prod: false)
  associate_public_ip = true

  # ---------------------------------------------------------------
  # 인스턴스 사양
  # ami_id: Amazon Linux 2023 최신 AMI (서울 리전)
  # 실제 최신 AMI ID는 콘솔 또는 CLI로 확인:
  #   aws ec2 describe-images --owners amazon \
  #     --filters "Name=name,Values=al2023-ami-*" \
  #     --query "Images | sort_by(@, &CreationDate) | [-1].ImageId"
  # ---------------------------------------------------------------
  ami_id        = "ami-0c9c942bd7bf113a2" # Amazon Linux 2023 (서울, 2024년 기준)
  instance_type = "t3.micro"

  # ---------------------------------------------------------------
  # SSH 키 페어
  # 사전에 EC2 콘솔에서 키 페어를 생성하고 이름을 지정
  # SSM Session Manager 사용 시 key_pair_name 불필요
  # ---------------------------------------------------------------
  key_pair_name = "dev-keypair"

  # ---------------------------------------------------------------
  # 보안 그룹 인바운드 규칙
  # dev: SSH(22), HTTP(80), HTTPS(443) 허용
  # prod: SSH 차단 (Bastion/SSM 경유), HTTP→HTTPS 리다이렉트
  # ---------------------------------------------------------------
  ingress_rules = [
    {
      description = "SSH 접근 (개발자 IP에서만)"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      # 실제 운영 시 개발자 IP 대역으로 제한할 것 (예: ["1.2.3.4/32"])
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTP 트래픽"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS 트래픽"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
  ]

  # ---------------------------------------------------------------
  # 스토리지
  # dev: 20 GiB (기본값, 개발 용도로 충분)
  # prod: 더 큰 볼륨 + 별도 데이터 볼륨 고려
  # ---------------------------------------------------------------
  root_volume_size = 20

  # ---------------------------------------------------------------
  # Elastic IP
  # dev: false (재시작 시 IP 변경 허용, 비용 절약)
  # prod: true (고정 IP 필요)
  # ---------------------------------------------------------------
  create_eip = false

  # ---------------------------------------------------------------
  # 상세 모니터링 (CloudWatch 1분 간격)
  # dev: false (기본 5분 간격으로 충분, 비용 절약)
  # prod: true (문제 빠른 감지를 위해 1분 간격)
  # ---------------------------------------------------------------
  enable_detailed_monitoring = false
}
