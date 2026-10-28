provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "eks-inventory-platform"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
