## CERT
resource "aws_route53_record" "external-mp" {
  depends_on = [
    aws_acm_certificate.external-mp
  ]
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
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

## LOADBALANCER
resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.ebsapps_lb.dns_name
    zone_id                = aws_lb.ebsapps_lb.zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "ebsapps_cname" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccms-ebsapps"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.external.fqdn]
}

## EBSDB
resource "aws_route53_record" "ebsdb" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccms-ebsdb.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_oracle_ebs.private_ip]

}
resource "aws_route53_record" "ebsdb_cname" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccms-ebsdb"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.ebsdb.fqdn]
}

## EBSWEBGATE
resource "aws_route53_record" "ebswgate" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].webgate_no_instances

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccms-ebswg${count.index + 1}.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_webgate[count.index].private_ip]

}
resource "aws_route53_record" "ebswgate_cname" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].webgate_no_instances

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccms-ebswg${count.index + 1}"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.ebswgate[count.index].fqdn]
}

## EBSACCESSGATE
resource "aws_route53_record" "ebsagate" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].accessgate_no_instances

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccms-ebsag${count.index + 1}.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_accessgate[count.index].private_ip]

}
resource "aws_route53_record" "ebsagate_cname" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].accessgate_no_instances

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccms-ebsag${count.index + 1}"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.ebsagate[count.index].fqdn]
}