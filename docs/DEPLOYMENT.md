# Deployment Guide

## 0. One-Time AWS & GitHub Setup

1. Create/confirm an AWS account, and an IAM user or role with admin
   access for the *manual* bootstrap step below (everything after that
   runs through GitHub Actions via OIDC — no long-lived keys needed).
2. Install Terraform >= 1.6 and the AWS CLI locally; run `aws configure`.
3. Push this repository to GitHub.
4. (Optional) Buy a domain and create a Route53 hosted zone for it if you
   want a custom URL — otherwise skip and use the free CloudFront domain.

## 1. Bootstrap the Remote State Backend (manual, once)

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: state_bucket_name must be globally unique,
# e.g. "gentrit-tfstate-portfolio-2026"

terraform init
terraform apply
terraform output
```

Copy the `state_bucket_name` and `lock_table_name` outputs — you'll need
them in the next step.

## 2. Point Environments at the Backend

Edit `terraform/environments/dev/backend.tf` and
`terraform/environments/prod/backend.tf`, replacing the placeholder
`bucket` value with your real state bucket name (the `key` should stay
`dev/terraform.tfstate` and `prod/terraform.tfstate` respectively — that's
what keeps the two environments' state files separate inside the same
bucket).

## 3. Create the GitHub OIDC Deploy Role

This role is what GitHub Actions assumes — you only need to create it
once, manually, the same way you bootstrapped the state backend (it can't
deploy itself, since CI doesn't exist as a trusted identity until this
role exists).

```hcl
# quick one-off root module, or paste into terraform/environments/dev temporarily
module "github_oidc" {
  source = "../../modules/iam-github-oidc"

  project_name      = "serverless-portfolio"
  state_bucket_name = "<your state bucket>"
  lock_table_name   = "terraform-state-locks"
  aws_region        = "us-east-1"
  account_id        = "<your AWS account ID>"

  allowed_subjects = [
    "repo:<your-github-username>/<repo-name>:ref:refs/heads/main",
    "repo:<your-github-username>/<repo-name>:ref:refs/heads/develop",
    "repo:<your-github-username>/<repo-name>:pull_request",
  ]
}

output "deploy_role_arn" {
  value = module.github_oidc.role_arn
}
```

Apply it, copy `deploy_role_arn`.

> If your AWS account already has a GitHub OIDC provider from another
> project, set `create_oidc_provider = false` and pass
> `existing_oidc_provider_arn` instead — an account can only have one
> provider per issuer URL.

## 4. Configure GitHub Repository Secrets & Environments

In **Settings → Secrets and variables → Actions**, add:

| Secret | Value |
|---|---|
| `AWS_DEPLOY_ROLE_ARN` | the `deploy_role_arn` from step 3 |
| `PROD_S3_BUCKET_NAME` | set after first prod apply (step 6) |
| `PROD_CLOUDFRONT_DISTRIBUTION_ID` | set after first prod apply (step 6) |

In **Settings → Environments**, create two environments:
- `development` — no protection rules needed
- `production` — add yourself as a **required reviewer**, so every prod
  deploy needs a manual approval click even though it's triggered by a
  push to `main`

## 5. First Manual Deploy — Dev

```bash
cd terraform/environments/dev
# edit terraform.tfvars: account_id, alert_email, etc.
terraform init
terraform plan
terraform apply
```

Upload the website and confirm it's live:

```bash
aws s3 sync ../../../website/ "s3://$(terraform output -raw s3_bucket_name)"
aws cloudfront create-invalidation \
  --distribution-id "$(terraform output -raw cloudfront_distribution_id)" \
  --paths "/*"
terraform output website_url
```

## 6. First Manual Deploy — Prod

Same as dev, in `terraform/environments/prod/`. After applying, copy the
`s3_bucket_name` and `cloudfront_distribution_id` outputs into the
`PROD_S3_BUCKET_NAME` / `PROD_CLOUDFRONT_DISTRIBUTION_ID` GitHub secrets
from step 4 — `deploy-website.yml` needs them.

## 7. From Here On: Let CI/CD Do It

- Push to `develop` → `terraform-cd-dev.yml` applies dev automatically.
- Open a PR to `main` → `terraform-ci.yml` runs `fmt`/`validate`/`plan`
  for both environments so you can review the diff before merging.
- Merge to `main` → `terraform-cd-prod.yml` applies prod, pausing for your
  approval in the `production` GitHub Environment.
- Edit `website/index.html` and push to `main` → `deploy-website.yml`
  syncs it to S3 and busts the CloudFront cache — no `terraform apply`
  needed for content-only changes.

## Tearing It Down

```bash
cd terraform/environments/dev && terraform destroy
cd ../prod && terraform destroy
# bootstrap is destroyed last, and only if you're done with the project entirely:
cd ../../bootstrap && terraform destroy
```

Note: the state bucket has `prevent_destroy = true` in the bootstrap
config — remove that lifecycle block first if you genuinely want to
delete it.
