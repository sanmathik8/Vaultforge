terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Remote state — configure a real backend (S3 + DynamoDB lock table)
  # before first apply. Left unconfigured here so this repo has no
  # hardcoded account-specific values.
  # backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
