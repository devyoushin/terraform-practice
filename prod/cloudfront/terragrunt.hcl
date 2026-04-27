### =============================================================================
### prod/cloudfront/terragrunt.hcl
### PROD 환경 CloudFront — CDN 배포
###
### 역할: 전 세계 엣지 로케이션을 통한 정적 콘텐츠 배포
###   - S3 assets 버킷 → CloudFront → 사용자 (CDN)
###   - 커스텀 도메인 + ACM 인증서 (HTTPS)
###   - 액세스 로그 S3 저장
###
### PROD 특징:
###   - price_class = "PriceClass_200"  (아시아 + 유럽 + 북미 엣지)
###   - enable_access_logs = true        (S3에 액세스 로그 저장)
###   - create_custom_domain = true      (커스텀 도메인 연결)
###   - WAF 연동 (별도 waf 모듈)
###
### 의존성:
###   - s3/assets → 원본(Origin) S3 버킷
###   - kms/s3    → (선택적) 암호화 키
###   - s3/logs   → 액세스 로그 버킷
###
### ⚠️ PROD 환경: 배포 전 반드시 plan 검토
### ⚠️ ACM 인증서는 반드시 us-east-1 리전에서 발급 (CloudFront 요구사항)
### ⚠️ 커스텀 도메인은 Route53 또는 DNS 제공업체에 CNAME 등록 필요
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "s3_assets" {
  config_path = "../s3/assets"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    bucket_id                  = "terraform-practice-prod-assets-123456789012"
    bucket_arn                 = "arn:aws:s3:::terraform-practice-prod-assets-123456789012"
    bucket_regional_domain_name = "terraform-practice-prod-assets-123456789012.s3.ap-northeast-2.amazonaws.com"
  }
}

dependency "s3_logs" {
  config_path = "../s3/logs"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    bucket_id  = "terraform-practice-prod-logs-123456789012"
    bucket_arn = "arn:aws:s3:::terraform-practice-prod-logs-123456789012"
  }
}

dependency "kms_s3" {
  config_path = "../kms/s3"
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/00000000-0000-0000-0000-000000000000"
  }
}

terraform {
  source = "../../cloudfront/modules/cloudfront"
}

inputs = {
  # ---------------------------------------------------------------
  # 원본(Origin) 설정
  # S3 assets 버킷을 CloudFront 원본으로 사용
  # OAC(Origin Access Control)로 S3 직접 접근 차단
  # ---------------------------------------------------------------
  origin_bucket_id                  = dependency.s3_assets.outputs.bucket_id
  origin_bucket_regional_domain_name = dependency.s3_assets.outputs.bucket_regional_domain_name

  # ---------------------------------------------------------------
  # 가격 등급 (Price Class)
  # prod: PriceClass_200 — 아시아, 유럽, 북미 엣지 로케이션 사용
  # dev:  PriceClass_100 — 북미/유럽만 (비용 절약)
  #
  # PriceClass_All: 전 세계 (최대 성능, 최고 비용)
  # PriceClass_200: 한국 서비스에 적합 (ap-northeast 포함)
  # PriceClass_100: 아시아 미포함 (한국 서비스 부적합)
  # ---------------------------------------------------------------
  price_class = "PriceClass_200"

  # ---------------------------------------------------------------
  # 액세스 로그
  # prod: S3에 CloudFront 액세스 로그 저장
  #   보안 분석, 트래픽 패턴 파악에 활용
  # ---------------------------------------------------------------
  enable_access_logs  = true
  access_logs_bucket  = dependency.s3_logs.outputs.bucket_id

  # ---------------------------------------------------------------
  # 커스텀 도메인 및 SSL
  # ⚠️ 아래 값들을 실제 도메인/인증서로 교체 필요!
  #
  # ACM 인증서 발급 방법 (반드시 us-east-1 에서!):
  #   aws acm request-certificate \
  #     --domain-name "*.example.com" \
  #     --validation-method DNS \
  #     --region us-east-1
  #
  # DNS 설정: CloudFront 도메인을 CNAME으로 등록
  #   CNAME: cdn.example.com → xxxxx.cloudfront.net
  # ---------------------------------------------------------------
  create_custom_domain  = true
  domain_name           = "REPLACE_WITH_DOMAIN"   # 예: cdn.example.com
  acm_certificate_arn   = "REPLACE_WITH_ACM_CERTIFICATE_ARN"  # us-east-1 인증서

  # ---------------------------------------------------------------
  # 캐시 설정
  # prod: 적절한 TTL 설정으로 캐시 히트율 최적화
  # ---------------------------------------------------------------
  default_ttl = 86400    # 1일 (초)
  max_ttl     = 31536000 # 1년
  min_ttl     = 0

  # ---------------------------------------------------------------
  # 보안 헤더
  # prod: 보안 헤더 자동 추가 (HSTS, CSP, X-Frame-Options 등)
  # ---------------------------------------------------------------
  enable_security_headers = true

  # ---------------------------------------------------------------
  # 지리적 제한 (선택적)
  # 특정 국가에서만 서비스하는 경우 설정
  # ---------------------------------------------------------------
  # geo_restriction_type      = "whitelist"
  # geo_restriction_locations = ["KR", "US", "JP"]
}
