output "zone_id" {
  value = data.aws_route53_zone.this.zone_id
}

output "fqdn" {
  value = aws_route53_record.alias_a.fqdn
}
