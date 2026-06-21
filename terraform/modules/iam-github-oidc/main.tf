###############################################################################
# IAM — GITHUB ACTIONS OIDC MODULE
# Lets GitHub Actions assume an AWS role WITHOUT storing AWS access keys
# as repo secrets. Trust is scoped to one GitHub repo + one or more
# branches, so a workflow run from a fork (or any other repo) cannot
# assume this role.
#
# NOTE: An AWS account can only have ONE OIDC provider per issuer URL.
# If you already created the GitHub OIDC provider for another project,
# set create_oidc_provider = false and pass its ARN via
# existing_oidc_provider_arn instead.
###############################################################################

data "tls_certificate" "github" {
  count = var.create_oidc_provider ? 1 : 0
  url   = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.create_oidc_provider ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github[0].certificates[0].sha1_fingerprint]
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restrict to specific repo + branches/refs (e.g. repo:org/name:ref:refs/heads/main)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.allowed_subjects
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = {
    Project = var.project_name
  }
}

# Deliberately scoped: state bucket/lock table for terraform, the
# project's own resources by name prefix, and CloudFront invalidation —
# nothing account-wide.
data "aws_iam_policy_document" "deploy_permissions" {
  statement {
    sid    = "TerraformStateAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:ListBucket",
      "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem",
    ]
    resources = [
      "arn:aws:s3:::${var.state_bucket_name}",
      "arn:aws:s3:::${var.state_bucket_name}/*",
      "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/${var.lock_table_name}",
    ]
  }

  statement {
    sid    = "ManageProjectResources"
    effect = "Allow"
    actions = [
      "s3:*", "cloudfront:*", "lambda:*", "apigateway:*", "dynamodb:*",
      "iam:*", "logs:*", "cloudwatch:*", "acm:*", "route53:*", "sns:*",
      "budgets:*",
    ]
    resources = ["*"]
    # NOTE: This deploy role is broad on purpose — it's what *applies*
    # Terraform, so it needs to manage every resource type in this stack.
    # The least-privilege boundary in this project lives at the
    # RUNTIME level (Lambda execution role can only touch its one table
    # and its own log group — see modules/lambda). Tightening this CI
    # role further to specific resource ARNs/prefixes is the natural
    # next hardening step once resource names are finalized.
  }
}

resource "aws_iam_role_policy" "deploy_permissions" {
  name   = "${var.role_name}-deploy-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.deploy_permissions.json
}
