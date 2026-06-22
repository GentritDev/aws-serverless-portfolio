# Cost Optimization

## Free Tier Mapping

| Service | Free Tier (12-month, new accounts) | This project's usage |
|---|---|---|
| Lambda | 1M requests + 400,000 GB-seconds/month, **forever free** (not just 12mo) | One 128MB function, a handful of invocations |
| API Gateway (HTTP API) | 1M requests/month for 12 months | One route, low traffic |
| DynamoDB | 25GB storage + 25 WCU/25 RCU equivalent **forever free** | One on-demand table, one item updated |
| S3 | 5GB storage, 20K GET / 2K PUT requests/month for 12 months | A few KB of static HTML/CSS |
| CloudFront | 1TB data transfer out + 10M requests/month for 12 months | `PriceClass_100`, low traffic |
| CloudWatch | 5GB log ingestion, 10 custom alarms, 1M API requests/month | 2 log groups, 3 alarms |
| SNS | 1,000 email notifications/month free | Alarm notifications only |

**Realistically $0–$1/month** at portfolio-level traffic (your own visits
+ reviewers/interviewers checking it out).

## What Costs Money Regardless of Tier

- **Route53 hosted zone**: ~$0.50/month per zone, **not** part of the free
  tier. This is why `enable_custom_domain` is a toggle — set it `false`
  and the entire stack runs on the free `*.cloudfront.net` URL with zero
  DNS cost. Flip it on once you're ready to put it on a real domain.
- Route53 *queries* are separately billed past the first 1M/month, but a
  portfolio site won't get near that.

## Design Decisions Made Specifically for Cost

- **HTTP API over REST API** in API Gateway — roughly 70% cheaper per
  request, and this project doesn't need REST-API-only features.
- **DynamoDB on-demand (`PAY_PER_REQUEST`)** instead of provisioned
  capacity — no cost while idle, no risk of a forgotten provisioned table
  burning budget for months.
- **CloudFront `PriceClass_100`** — only North America + Europe edge
  locations, instead of `PriceClass_All`. A personal portfolio doesn't
  need Asia-Pacific/South America edge presence, and this materially cuts
  the per-GB transfer rate.
- **Short CloudWatch log retention** (14 days dev / 30 days prod) instead
  of the default "Never Expire" — logs accumulate storage cost forever
  otherwise, especially across a months-long portfolio project.
- **128MB Lambda memory** — right-sized for a function that does one
  DynamoDB call; Lambda cost scales with memory × duration, so over-
  provisioning memory you don't need directly wastes free-tier GB-seconds.
- **S3 lifecycle rule** expires noncurrent object versions after 30 days,
  so bucket versioning (a durability win) doesn't silently grow storage
  cost from every redeploy.

## The Safety Net: AWS Budgets

`modules/monitoring` provisions an `aws_budgets_budget` with an email
alert at 80% of a configurable monthly threshold (default $5 dev /
$10 prod). This is the actual financial backstop — even if every other
cost-control decision above somehow failed (e.g. a traffic spike, a
misconfigured loop calling the API), you get an email before the bill
becomes a surprise.

## If You Wanted to Scale This Up Later

- CloudFront caching could be tuned more aggressively (longer TTLs) to
  cut S3 GET requests further at real scale.
- DynamoDB could switch to provisioned capacity + auto-scaling once
  traffic is predictable — usually cheaper than on-demand at sustained
  high volume.
- Lambda **provisioned concurrency** would remove cold starts but costs
  money continuously — not worth it for a low-traffic portfolio API.
