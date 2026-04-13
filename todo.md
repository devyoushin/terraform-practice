# Terraform 폴더 남은 작업

## A. .pre-commit-config.yaml 추가 (9개)
- [x] terraform-cloudfront
- [x] terraform-cloudwatch
- [x] terraform-dynamodb
- [x] terraform-ecr
- [x] terraform-kms
- [x] terraform-secrets-manager
- [x] terraform-waf
- [x] terraform-bastion
- [x] terraform-elasticache

## B. Makefile 추가 (3개)
- [x] terraform-bastion
- [x] terraform-elasticache
- [x] terraform-waf

## C. terraform-tgw env 파일 보완
- [x] env/dev/backend.tf
- [x] env/dev/variables.tf
- [x] env/dev/terraform.tfvars
- [x] env/prod/backend.tf
- [x] env/prod/variables.tf
- [x] env/prod/terraform.tfvars

## D. 문서 작업
- [x] 루트 README.md 작성
- [x] CLAUDE.md 작성
- [x] backup/README.md 작성
- [x] guardduty/README.md 작성
- [x] codepipeline/README.md 작성

## E. 미구현 모듈 완성

### terraform-backup
- [x] modules/backup/main.tf
- [x] modules/backup/variables.tf
- [x] modules/backup/outputs.tf
- [x] envs/dev/main.tf
- [ ] envs/dev/variables.tf
- [ ] envs/dev/terraform.tfvars
- [ ] envs/dev/backend.tf
- [ ] envs/staging/ (main, variables, tfvars, backend)
- [ ] envs/prod/ (main, variables, tfvars, backend)
- [ ] Makefile
- [ ] .pre-commit-config.yaml
- [ ] terraform.tfvars.example

### terraform-guardduty
- [x] modules/guardduty/main.tf
- [x] modules/guardduty/variables.tf
- [x] modules/guardduty/outputs.tf
- [x] envs/dev/main.tf
- [ ] envs/dev/variables.tf
- [ ] envs/dev/terraform.tfvars
- [ ] envs/dev/backend.tf
- [ ] envs/staging/ (main, variables, tfvars, backend)
- [ ] envs/prod/ (main, variables, tfvars, backend)
- [ ] Makefile
- [ ] .pre-commit-config.yaml
- [ ] terraform.tfvars.example

### terraform-codepipeline
- [x] modules/codepipeline/main.tf
- [ ] modules/codepipeline/variables.tf
- [ ] modules/codepipeline/outputs.tf
- [ ] envs/dev/ (main, variables, tfvars, backend)
- [ ] envs/staging/ (main, variables, tfvars, backend)
- [ ] envs/prod/ (main, variables, tfvars, backend)
- [ ] Makefile
- [ ] .pre-commit-config.yaml
- [ ] terraform.tfvars.example

### terraform-route53
- [x] modules/route53/main.tf
- [x] modules/route53/variables.tf
- [x] modules/route53/outputs.tf
- [x] envs/dev/ (main, variables, tfvars, backend)
- [ ] envs/staging/ (main, variables, tfvars, backend)
- [ ] envs/prod/ (main, variables, tfvars, backend)

### terraform-sqs-sns
- [x] modules/sqs-sns/main.tf
- [x] modules/sqs-sns/variables.tf
- [x] modules/sqs-sns/outputs.tf
- [x] envs/dev/ (main, variables, tfvars, backend)
- [ ] envs/staging/ (main, variables, tfvars, backend)
- [ ] envs/prod/ (main, variables, tfvars, backend)
