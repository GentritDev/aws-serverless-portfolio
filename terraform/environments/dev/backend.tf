###############################################################################
# Remote state backend. Values must match the outputs from terraform/bootstrap.
# Terraform does not allow variables here — fill in literal values, or pass
# them with `terraform init -backend-config=...` (see docs/DEPLOYMENT.md).
###############################################################################

terraform {
  backend "s3" {
    bucket         = "CHANGE-ME-globally-unique-tfstate-bucket"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
