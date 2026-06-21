###############################################################################
# DYNAMODB MODULE
# On-demand (PAY_PER_REQUEST) billing — no provisioned capacity to pay for
# while idle, fits AWS Free Tier (25 GB storage + 25 WCU/RCU equivalent).
###############################################################################

resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.hash_key

  attribute {
    name = var.hash_key
    type = "S"
  }

  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  server_side_encryption {
    enabled = true # uses AWS-owned KMS key, no extra cost
  }

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
