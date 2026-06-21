# Interview Questions & Answers

Practice these out loud, not just read them — the goal is to be able to
explain *why* you made each decision, not recite definitions.

---

**Q: Walk me through what happens when someone visits your site.**

A: DNS resolves through Route53 to a CloudFront distribution. CloudFront
serves the static HTML/CSS/JS from a private S3 bucket using Origin
Access Control — the bucket itself has no public access at all. The
page's JavaScript then calls an API Gateway HTTP API endpoint, which
invokes a Lambda function via AWS_PROXY integration. The Lambda
atomically increments a counter item in DynamoDB using an `UpdateItem`
with an `ADD` expression, and returns the new count as JSON, which the
frontend displays.

---

**Q: Why Terraform instead of clicking around the AWS Console, or
CloudFormation?**

A: Console changes aren't reproducible or reviewable — there's no diff,
no history, no way to know what changed between two states of the
infrastructure. Terraform gives me a plan/apply workflow I can review in
a pull request before anything touches AWS, and the same code deploys
dev and prod identically, which removes "it worked in dev" drift.
I chose Terraform specifically over CloudFormation because it's
cloud-agnostic (the same skills transfer to GCP/Azure projects, both of
which I've also worked with), and its module system maps cleanly onto
how I wanted this project organized — one module per AWS service.

---

**Q: How does your CI/CD pipeline actually authenticate to AWS? Where are
the access keys stored?**

A: There aren't any. GitHub Actions uses OIDC federation — GitHub issues
a short-lived signed token for each workflow run, and AWS trusts that
token (via an `aws_iam_openid_connect_provider`) to let the workflow
assume an IAM role, scoped by a trust-policy condition that checks the
token's `sub` claim matches this specific repo and branch. If someone
forked my repo and tried to run the same workflow, the `sub` claim
wouldn't match and `AssumeRoleWithWebIdentity` would be denied. There's
nothing long-lived to leak or rotate.

---

**Q: What does "least privilege" actually mean in this project — give a
concrete example.**

A: The Lambda's IAM role isn't `AWSLambdaBasicExecutionRole` plus
`AmazonDynamoDBFullAccess` — I wrote a custom policy that grants exactly
`logs:CreateLogStream` and `logs:PutLogEvents`, scoped to that one
function's specific log group ARN, and exactly `dynamodb:GetItem`,
`PutItem`, `UpdateItem`, scoped to that one table's ARN. If that
function's code were ever compromised, it couldn't read a different
table or write to a different function's logs — the blast radius is
contained to exactly the resources it needs.

---

**Q: Your CI deploy role looks broader than that, though — isn't that a
contradiction?**

A: It's a deliberate, documented tradeoff, not an oversight — I called
it out directly in the module's comments rather than hiding it. The
deploy role needs broad permissions because Terraform's job is to
*create and modify* every resource type in the stack; you can't scope a
role down to "exactly what already exists" when its whole purpose is
provisioning. The actual security boundary is: (1) only this repo and
branch can assume the role at all (OIDC trust condition), and (2) the
*runtime* roles — like Lambda's — are tightly scoped, because those are
what's exposed to actual traffic. The next hardening step, if I kept
building this, would be narrowing the deploy role to specific resource
ARN prefixes once names are finalized.

---

**Q: Why HTTP API instead of REST API in API Gateway?**

A: HTTP APIs are roughly 70% cheaper per request and have lower latency,
and this project doesn't need REST-API-specific features like request/
response validation models, API keys, or usage plans. REST API would be
the right call if I needed those, but for a simple proxy-to-Lambda
endpoint, HTTP API is the leaner choice — and choosing the simpler tool
when it's sufficient is itself a decision worth being able to defend.

---

**Q: Why DynamoDB on-demand instead of provisioned capacity?**

A: On-demand bills per request with no capacity to plan or pay for while
idle, which fits a project where I can't predict traffic and don't want
idle cost. Provisioned capacity (with auto-scaling) becomes cheaper at
sustained, predictable high volume — it's the right call for a mature
production system with known traffic patterns, not for a low-traffic
portfolio API.

---

**Q: How is your Terraform structured to support multiple environments
without duplicating logic?**

A: All resource logic lives in `terraform/modules/` — nine modules, one
per AWS service or concern. `terraform/environments/dev` and `.../prod`
each just *compose* those modules with different input variables (log
retention, alarm thresholds, point-in-time-recovery, custom domain). If I
add a `staging` environment, it's a copy of the `dev` folder and a new
`backend.tf` key — no module code changes. State is also isolated per
environment: same S3 bucket, different `key` (`dev/terraform.tfstate` vs
`prod/terraform.tfstate`), so a `terraform apply` in dev can never touch
prod's state.

---

**Q: What's the purpose of the DynamoDB table in your Terraform state
backend — that's a different table from your app's table, right?**

A: Right, completely separate. The state-locking table only stores a
`LockID` — it's how Terraform prevents two `apply` runs (say, my laptop
and a GitHub Actions run) from racing and corrupting the same state file.
Without it, a concurrent apply could leave the state file in an
inconsistent view of reality. The app's DynamoDB table is unrelated — it
just stores the visitor count.

---

**Q: How would you debug a 500 error a user reports on the live site?**

A: First, CloudWatch Logs for the Lambda function — every invocation
logs the incoming event and any exception with a stack trace. Second,
the API Gateway access log (also in CloudWatch) shows the request ID,
status code, and integration error message, which I can cross-reference
with the Lambda log using that request ID. Third, if it's a pattern
rather than a one-off, the CloudWatch Alarm on Lambda errors would have
already fired and emailed me via SNS before the user even reported it.

---

**Q: What would you change if this needed to handle real production
traffic at scale?**

A: A few things: add CloudFront caching tuned more aggressively to cut
origin requests; consider moving DynamoDB to provisioned capacity with
auto-scaling once traffic is predictable, since that's usually cheaper
than on-demand at volume; add a WAF in front of CloudFront for basic
exploit protection; and narrow the CI/CD IAM role to specific resource
ARNs now that they're no longer changing shape. I'd also add
authentication (Cognito) if any endpoint needed to be user-specific
rather than public/anonymous like this visitor counter.

---

**Q: Why did you make the custom domain optional instead of just
requiring one?**

A: Two reasons. Practically, Route53 hosted zones aren't free
($0.50/month), so making it a toggle (`enable_custom_domain`) lets the
whole stack run at genuinely $0 for anyone — including someone reviewing
this project — without needing to own a domain first. Architecturally,
it forced me to handle a real conditional-resource pattern in
Terraform (`count = var.enable_custom_domain ? 1 : 0` on the ACM and
Route53 modules), which is a pattern that comes up constantly in real
infrastructure code.
