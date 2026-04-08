output "cluster_name"      { value = module.eks.cluster_name;      description = "EKS 클러스터 이름" }
output "cluster_endpoint"  { value = module.eks.cluster_endpoint;  description = "EKS API 서버 엔드포인트" }
output "oidc_provider_arn" { value = module.eks.oidc_provider_arn; description = "OIDC Provider ARN (IRSA 설정 시 사용)" }
output "vpc_id"            { value = module.vpc.vpc_id;            description = "VPC ID" }
output "private_subnets"   { value = module.vpc.private_subnets;   description = "프라이빗 서브넷 ID 목록" }
