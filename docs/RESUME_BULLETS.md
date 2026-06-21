# Resume Bullet Points

Pick 3–5 that fit the role you're applying for — don't use all of them,
it gets repetitive. Swap numbers/specifics if yours differ.

## Strong, general-purpose versions

- Designed and deployed a production-style serverless web application on
  AWS (Route53, CloudFront, S3, API Gateway, Lambda, DynamoDB) using 100%
  modular Terraform across isolated dev/prod environments with S3 remote
  state and DynamoDB state locking.

- Built a CI/CD pipeline in GitHub Actions implementing OIDC federation
  for AWS authentication, eliminating long-lived access keys; pipeline
  runs `terraform fmt`/`validate`/`plan` on every pull request and
  gates production deploys behind manual approval.

- Implemented least-privilege IAM throughout the stack, scoping the
  Lambda execution role to exactly two CloudWatch Logs actions and three
  DynamoDB actions on specific resource ARNs rather than managed
  full-access policies.

- Architected the frontend delivery layer with CloudFront and S3 Origin
  Access Control, eliminating public bucket access entirely while serving
  static assets through a globally-distributed CDN with TLS termination.

- Set up full observability for a serverless application: CloudWatch
  Logs with environment-specific retention, three CloudWatch Alarms
  (Lambda errors, API Gateway 5xx, DynamoDB throttling) routed through
  SNS, and an AWS Budgets cost-guard with automated email alerting.

## Shorter / single-line versions

- Built a production-grade serverless AWS application (Lambda, API
  Gateway, DynamoDB, CloudFront, S3) provisioned entirely through modular
  Terraform with automated CI/CD via GitHub Actions.

- Implemented infrastructure-as-code best practices: remote state
  locking, least-privilege IAM, GitHub OIDC authentication, and
  environment-isolated dev/prod deployments.

## If the role emphasizes cost/ops specifically

- Optimized a serverless AWS stack to operate within the Free Tier through
  on-demand DynamoDB billing, HTTP API (vs. REST API), tuned CloudFront
  price class, and automated CloudWatch log retention policies, backed by
  an AWS Budgets cost-alerting safety net.

## If the role emphasizes security specifically

- Eliminated static AWS credentials from CI/CD by implementing GitHub
  Actions OIDC federation with a repo/branch-scoped IAM trust policy, and
  enforced least-privilege, resource-scoped IAM permissions for all
  runtime compute.
