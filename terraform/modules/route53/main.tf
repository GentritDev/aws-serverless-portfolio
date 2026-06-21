###############################################################################
# ROUTE53 MODULE
# Looks up an EXISTING hosted zone (you buy/own the domain and create the
# zone once, manually — recreating a hosted zone in Terraform on every
# apply is unnecessary and the $0.50/month cost shouldn't be tied to
# environment lifecycle). Creates an alias A/AAAA record pointing at
# CloudFront.
###############################################################################

data "aws_route53_zone" "this" {
  name         = var.root_domain_name
  private_zone = false
}

resource "aws_route53_record" "alias_a" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alias_aaaa" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.record_name
  type    = "AAAA"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
