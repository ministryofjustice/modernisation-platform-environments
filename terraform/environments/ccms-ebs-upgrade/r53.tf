# EBS DB
resource "aws_route53_record" "ebsdb" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ccms-ebs-db-upgrade.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.ec2_oracle_ebs.private_ip]
}

# EBS Conc
resource "aws_route53_record" "ebsconc" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].conc_no_instances
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ccms-ebs-conc-upgrade.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.ec2_oracle_conc[count.index].private_ip]
}

# EBS Apps
resource "aws_route53_record" "ebsapps" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].ebsapps_no_instances
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ccms-ebs-app${count.index + 1}-upgrade.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.ec2_ebsapps[count.index].private_ip]
}

# EBS ALB
resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccms-ebs-upgrade.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.ebsapps_lb.dns_name
    zone_id                = aws_lb.ebsapps_lb.zone_id
    evaluate_target_health = true
  }
}

# AccessGate Instances
resource "aws_route53_record" "accessgate_ec2" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].accessgate_no_instances

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${local.application_data.accounts[local.environment].accessgate_dns_prefix}${count.index + 1}-upgrade.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_accessgate[count.index].private_ip]
}

# WebGate Instances
resource "aws_route53_record" "webgate_ec2" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].webgate_no_instances

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${local.application_data.accounts[local.environment].webgate_dns_prefix}${count.index + 1}-upgrade.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_webgate[count.index].private_ip]
}

## EBSWEBGATE LB DNS
resource "aws_route53_record" "ebswgate" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "portal-ag-upgrade.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"
  alias {
    name                   = aws_lb.webgate_lb.dns_name
    zone_id                = aws_lb.webgate_lb.zone_id
    evaluate_target_health = false
  }
}


## FTP
resource "aws_route53_record" "ftp" {
  count    = local.is-test ? 1 : 0
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ftp-upgrade.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.ec2_ftp[0].private_ip]
}
