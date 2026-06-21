# Security

## Identity & Access

- **No static AWS access keys anywhere** — not in GitHub secrets, not on
  disk. GitHub Actions authenticates via OIDC federation
  (`aws_iam_openid_connect_provider` + a role whose trust policy checks
  the `sub` claim against this exact repo and branch). A leaked GitHub
  secret can't be replayed from outside an Actions run, and access can be
  revoked by deleting one IAM role — no key rotation across machines.
- **Least privilege at runtime**: the Lambda execution role
  (`modules/lambda`) is scoped to exactly two actions on its own log
  group ARN and three actions on its one DynamoDB table ARN. It cannot
  read any other table, write to any other log group, or call any other
  AWS service.
- **Broader, explicitly-scoped CI role**: the GitHub Actions deploy role
  is intentionally wider, since it runs `terraform apply` against every
  resource type in the stack. The honest tradeoff (and the natural next
  hardening step, called out directly in
  `modules/iam-github-oidc/main.tf`) is narrowing `ManageProjectResources`
  to specific ARNs/prefixes once resource names are finalized, rather
  than `Resource: "*"` within this project's service list.
- IAM policies are written as `aws_iam_policy_document` data sources
  (not raw JSON heredocs) so Terraform validates their structure at plan
  time.

## Network & Data Exposure

- The S3 bucket has **zero** public access: no public ACLs, no bucket
  policy allowing `Principal: "*"`, no static-website-hosting endpoint.
  `aws_s3_bucket_public_access_block` blocks all four public-access
  vectors at the bucket level regardless of any future policy mistake.
  The only path in is CloudFront's Origin Access Control, scoped by an
  `AWS:SourceArn` condition to this exact distribution.
- All traffic to CloudFront is forced to HTTPS
  (`viewer_protocol_policy = "redirect-to-https"`), with a minimum TLS
  version of `TLSv1.2_2021` when a custom domain/ACM cert is in use.
- API Gateway CORS is restricted to the actual site origin in
  production (`var.enable_custom_domain ? [the real domain] : ["*"]`) —
  the wildcard fallback only applies to the no-custom-domain dev path.
- API Gateway throttling (burst/rate limits) bounds the blast radius of
  an unauthenticated public endpoint being scraped or abused.

## Data Protection

- S3: server-side encryption (SSE-S3/AES256) on all objects, bucket
  versioning enabled (recovers from accidental overwrite/delete).
- DynamoDB: encryption at rest enabled; point-in-time recovery on in
  prod (35-day continuous backups).
- Terraform state: the state bucket itself is encrypted, versioned, and
  has all public access blocked — state files can contain sensitive
  values, so they get the same protection as the resources they describe.

## Observability as a Security Control

- API Gateway access logs and Lambda logs are retained in CloudWatch
  (14/30 days), giving an audit trail of every request.
- CloudWatch Alarms on Lambda errors and API Gateway 5xx responses mean a
  misconfiguration or attempted abuse surfaces as an email alert, not
  silence.

## What's Deliberately Out of Scope (and why)

A from-scratch project has to draw a line somewhere. Documented honestly
here rather than silently skipped:

- **WAF** is not attached to CloudFront — would add real protection
  against common web exploits, but also a small monthly cost outside
  the free tier. Natural "v2" addition.
- **API authentication** (Cognito/API keys) — the `/visitors` endpoint is
  intentionally public/anonymous (it's a visitor counter). A project with
  user-specific data would need Cognito authorizers on the API Gateway
  route.
- **Secrets Manager / Parameter Store** — this project has no API keys or
  passwords to store; if it grows one, this is where it would live rather
  than as a Lambda environment variable.
