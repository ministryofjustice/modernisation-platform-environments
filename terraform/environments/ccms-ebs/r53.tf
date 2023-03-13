resource "aws_route53_record" "ebsdb" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ebsdb.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_oracle_ebs.private_ip]

}
resource "aws_route53_record" "ebsdb_cname" {
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ebsdb"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.ebsdb.fqdn]
}




/*
resource "aws_route53_record" "external-mp" {
  provider = aws.core-network-services
  for_each = {
    for dvo in aws_acm_certificate.external-mp[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  #zone_id         = data.aws_route53_zone.external.zone_id
  zone_id = data.aws_route53_zone.network-services.zone_id
}

resource "aws_acm_certificate_validation" "external-mp" {
  certificate_arn         = aws_acm_certificate.external-mp[0].arn
  validation_record_fqdns = [for record in aws_route53_record.external-mp : record.fqdn]
}
*/