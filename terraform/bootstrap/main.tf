###############################################################################
# BOOTSTRAP — run this ONCE, manually, before any environment is deployed.
#
# This creates the S3 bucket + DynamoDB table that hold Terraform remote
# state for the dev/ and prod/ environments. It intentionally has its OWN
# local state (chicken-and-egg problem: you can't store state in a bucket
# that doesn't exist yet). After applying, the bucket/table names become
# inputs to terraform/environments/{dev,prod}/backend.tf.
#
# Usage:
#   cd terraform/bootstrap
#   terraform init
#   terraform apply
###############################################################################

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 bucket that will store terraform.tfstate for every environment
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  # Protects the bucket from being destroyed by `terraform destroy`
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
    Purpose   = "terraform-remote-state"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled" # lets you recover a previous state file if it gets corrupted
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table used for Terraform state locking (prevents two `apply`
# runs — e.g. a developer laptop and a GitHub Actions run — from racing).
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST" # free-tier friendly, no idle cost
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
    Purpose   = "terraform-state-locking"
  }
}
