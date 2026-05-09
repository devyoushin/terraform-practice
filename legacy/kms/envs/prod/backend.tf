# terraform { backend "s3" { bucket = "my-company-prod-tfstate"; key = "prod/kms/terraform.tfstate"; region = "ap-northeast-2"; encrypt = true; dynamodb_table = "terraform-state-lock" } }
