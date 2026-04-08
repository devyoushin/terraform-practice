# EKS Terraform 구성 가이드

## 디렉토리 구조

```
terraform/
├── envs/
│   └── dev/
│       ├── main.tf        # Provider, Module 호출, Access Entry
│       ├── variables.tf   # 리전 변수
│       └── backend.tf     # 상태 파일 백엔드 설정
└── modules/
    ├── vpc/               # VPC, 서브넷, NAT Gateway
    ├── eks/               # EKS 클러스터, Managed Node Group
    └── karpenter/         # Karpenter IAM, Helm, NodePool, EC2NodeClass
```

---

## 사전 요구사항

### 1. AWS CLI

AWS API 호출 및 EKS 인증 토큰 발급에 사용됩니다.

**설치**
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
```

**자격증명 설정**
```bash
aws configure
# AWS Access Key ID:     ← IAM 사용자 Access Key 입력
# AWS Secret Access Key: ← IAM 사용자 Secret Key 입력
# Default region name:   ap-northeast-2
# Default output format: json
```

> AWS IAM 사용자에게 EKS, EC2, VPC, IAM, SQS, EventBridge 관련 권한이 필요합니다.
> 테스트 환경에서는 `AdministratorAccess` 정책을 사용할 수 있습니다.

**설치 확인**
```bash
aws --version
aws sts get-caller-identity
```

---

### 2. Terraform

**설치**
```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Linux
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform
```

**설치 확인**
```bash
terraform version
# Terraform v1.5.0 이상 필요
```

---

### 3. kubectl

Kubernetes 클러스터 제어 및 Karpenter CRD 배포에 사용됩니다.

**설치**
```bash
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**설치 확인**
```bash
kubectl version --client
```

---

### 4. Helm

Karpenter Helm 차트 설치에 내부적으로 사용됩니다 (Terraform helm provider가 사용).

**설치**
```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**설치 확인**
```bash
helm version
```

---

### 5. IAM 권한 확인

Terraform을 실행하는 IAM 사용자 또는 Role에 아래 권한이 필요합니다.

| 서비스 | 필요 권한 |
|--------|-----------|
| VPC / EC2 | VPC, Subnet, NAT Gateway, Security Group 생성/삭제 |
| EKS | 클러스터 생성/삭제, Node Group 관리, Access Entry 관리 |
| IAM | Role, Policy, Instance Profile 생성/삭제 |
| SQS | 큐 생성/삭제, 큐 정책 설정 |
| EventBridge | 규칙 및 대상 생성/삭제 |
| SSM | Parameter 읽기 |

---

## 배포 전 설정 값 확인

`envs/dev/main.tf`에서 아래 항목을 환경에 맞게 수정하세요.

| 항목 | 위치 | 기본값 | 설명 |
|------|------|--------|------|
| 클러스터 이름 | `locals.cluster_name` | `dev-eks` | EKS 클러스터 이름 |
| VPC CIDR | `module.vpc.cidr` | `10.0.0.0/16` | VPC IP 대역 |
| AZ 목록 | `module.vpc.azs` | `ap-northeast-2a/c` | 사용할 가용 영역 |
| Private 서브넷 | `module.vpc.private_subnets` | `10.0.1~2.0/24` | 노드 배포 서브넷 |
| Public 서브넷 | `module.vpc.public_subnets` | `10.0.101~102.0/24` | 로드밸런서 서브넷 |
| 노드 인스턴스 타입 | `modules/eks/main.tf` | `t3.medium` | 기본 Managed Node Group 타입 |
| Karpenter 버전 | `modules/karpenter/main.tf` | `1.1.1` | Helm 차트 버전 |
| AWS 리전 | `envs/dev/variables.tf` | `ap-northeast-2` | 배포 리전 |

---

## 배포 순서

### 작업 디렉토리 이동

```bash
cd envs/dev
```

### 1단계: 초기화

provider 플러그인과 모듈을 다운로드합니다.

```bash
terraform init
```

### 2단계: VPC + EKS 클러스터 먼저 생성

> helm/kubectl provider가 EKS 클러스터 엔드포인트를 참조하기 때문에
> 클러스터가 존재한 이후에 Karpenter를 설치할 수 있습니다.

```bash
terraform apply -target=module.vpc -target=module.eks
```

소요 시간: 약 15~20분 (EKS 클러스터 생성)

### 3단계: Karpenter 포함 전체 적용

```bash
terraform apply
```

소요 시간: 약 3~5분 (Karpenter IAM, Helm, NodePool, EC2NodeClass)

---

## 배포 확인

### kubeconfig 업데이트

```bash
aws eks update-kubeconfig --region ap-northeast-2 --name dev-eks
```

### 노드 상태 확인

```bash
kubectl get nodes
```

### Karpenter 파드 상태 확인

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter
```

### Karpenter NodePool / EC2NodeClass 확인

```bash
kubectl get nodepool
kubectl get ec2nodeclass
```

### Karpenter 로그 확인

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter --tail=50
```

---

## 리소스 삭제

> 삭제 시 모든 워크로드와 데이터가 제거됩니다. 신중히 진행하세요.

```bash
# Karpenter NodePool / EC2NodeClass 먼저 삭제 (노드 드레인 포함)
kubectl delete nodepool --all
kubectl delete ec2nodeclass --all

# Terraform으로 전체 인프라 삭제
terraform destroy
```

---

## 원격 백엔드 설정 (선택 - 팀 협업 시 권장)

`envs/dev/backend.tf`의 주석을 해제하고 S3 버킷을 먼저 생성하세요.

```bash
# S3 버킷 생성
aws s3 mb s3://your-tfstate-bucket --region ap-northeast-2

# DynamoDB 테이블 생성 (상태 잠금용)
aws dynamodb create-table \
  --table-name your-tfstate-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-2

# 백엔드 마이그레이션 (로컬 → S3)
terraform init -migrate-state
```

---

## 트러블슈팅

### terraform init 실패 - provider 다운로드 오류

```bash
# provider 캐시 초기화 후 재시도
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### EKS 노드가 Ready 상태가 아닌 경우

```bash
# aws-auth 또는 access entry 확인
aws eks list-access-entries --cluster-name dev-eks

# 노드 이벤트 확인
kubectl describe node <node-name>
```

### Karpenter가 노드를 프로비저닝하지 않는 경우

```bash
# Karpenter 컨트롤러 로그 확인
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter | grep -i error

# EC2NodeClass 상태 확인
kubectl describe ec2nodeclass default

# NodePool 상태 확인
kubectl describe nodepool default
```
