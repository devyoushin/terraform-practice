### =============================================================================
### dev/cloudfront/terragrunt.hcl
### DEV 환경 CloudFront CDN
###
### 역할: S3 assets 버킷의 정적 파일을 전 세계에 빠르게 배포하는 CDN
###       OAI(Origin Access Identity)로 S3 직접 접근 차단
### DEV 특징:
###   - price_class = "PriceClass_100": 북미+유럽만 (최저 비용)
###     (prod: PriceClass_All — 전 세계)
###   - enable_access_logs = false: 액세스 로그 비활성화 (비용 절약)
###   - create_custom_domain = false: 커스텀 도메인 없음 (*.cloudfront.net 사용)
###   - 캐시 TTL: 짧게 설정 (개발 중 콘텐츠 변경 즉시 반영)
### 의존성: s3/assets (오리진 버킷)
### =============================================================================

include "root" {
  path = find_in_parent_folders()
}

dependency "s3_assets" {
  config_path = "../s3/assets"

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    bucket_id                  = "terraform-practice-dev-assets"
    bucket_arn                 = "arn:aws:s3:::terraform-practice-dev-assets"
    bucket_regional_domain_name = "terraform-practice-dev-assets.s3.ap-northeast-2.amazonaws.com"
    bucket_domain_name         = "terraform-practice-dev-assets.s3.amazonaws.com"
  }
}

terraform {
  source = "../../cloudfront/modules/cloudfront"
}

inputs = {
  # ---------------------------------------------------------------
  # 오리진 설정 — S3 assets 버킷
  # CloudFront → S3 직접 접근 (OAI 사용으로 S3 퍼블릭 접근 차단)
  # ---------------------------------------------------------------
  s3_bucket_id                  = dependency.s3_assets.outputs.bucket_id
  s3_bucket_regional_domain_name = dependency.s3_assets.outputs.bucket_regional_domain_name

  # ---------------------------------------------------------------
  # Price Class (엣지 로케이션 범위)
  # PriceClass_100: 북미 + 유럽 (최저 비용)
  # PriceClass_200: + 아시아, 중동, 아프리카
  # PriceClass_All: 전 세계 (최고 성능, 최고 비용)
  # dev: PriceClass_100 (비용 절약, 한국 사용자도 접근 가능하나 지연 발생)
  # prod: PriceClass_All 또는 PriceClass_200
  # ---------------------------------------------------------------
  price_class = "PriceClass_100"

  # ---------------------------------------------------------------
  # 액세스 로그
  # dev: false (S3 로그 저장 비용 절약)
  # prod: true (CDN 트래픽 분석 및 보안 감사)
  # ---------------------------------------------------------------
  enable_access_logs = false

  # ---------------------------------------------------------------
  # 커스텀 도메인 (Route53 + ACM)
  # dev: false (기본 *.cloudfront.net 도메인 사용)
  # prod: true (예: cdn.example.com — ACM 인증서 + Route53 A 레코드)
  # ---------------------------------------------------------------
  create_custom_domain = false

  # ---------------------------------------------------------------
  # 캐시 설정
  # dev: 짧은 TTL (변경사항 빠른 반영)
  # prod: 긴 TTL (캐시 히트율 극대화)
  # ---------------------------------------------------------------
  default_ttl = 60   # 1분 (dev: 콘텐츠 변경 즉시 확인)
  max_ttl     = 300  # 5분

  # ---------------------------------------------------------------
  # HTTPS 설정
  # dev: redirect-to-https (HTTP → HTTPS 자동 리다이렉트)
  # ---------------------------------------------------------------
  viewer_protocol_policy = "redirect-to-https"
}
