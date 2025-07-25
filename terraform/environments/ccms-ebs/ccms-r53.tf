## LOADBALANCER
resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.ebsapps_nlb.dns_name
    zone_id                = aws_lb.ebsapps_nlb.zone_id
    evaluate_target_health = true
  }
}

## Prod Network Loadbalancer
resource "aws_route53_record" "prod_ebs_nlb" {
  provider = aws.core-network-services
  count    = local.is-production ? 1 : 0
  zone_id  = data.aws_route53_zone.legalservices.zone_id
  name     = "ccmsebs.legalservices.gov.uk"
  type     = "A"
  alias {
    name                   = aws_lb.ebsapps_nlb.dns_name
    zone_id                = aws_lb.ebsapps_nlb.zone_id
    evaluate_target_health = true
  }
}

# Prod LB EBS Apps DNS
resource "aws_route53_record" "prod_ebsapp_lb" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.prod-network-services.zone_id
  name     = "${var.networking[0].application}.ccms-ebs.service.justice.gov.uk"
  type     = "A"

  alias {
    name                   = aws_lb.ebsapps_nlb.dns_name
    zone_id                = aws_lb.ebsapps_nlb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ebslb_cname" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccms-ebslb"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.external.fqdn]
}

## EBSDB
resource "aws_route53_record" "ebsdb" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  #name    = "ccms-ebs-db.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  name    = "ccms-ebs-db.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_oracle_ebs.private_ip]
}

## PROD EBSDB
resource "aws_route53_record" "prod_ebsdb" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.prod-network-services.zone_id
  name     = "ccms-ebs-db.ccms-ebs.service.justice.gov.uk"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.ec2_oracle_ebs.private_ip]
}

/*resource "aws_route53_record" "ebsdb_cname" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccms-ebs-db"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.ebsdb.fqdn]
}*/

## EBSAPPS
resource "aws_route53_record" "ebsapps" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].ebsapps_no_instances
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ccms-ebs-app${count.index + 1}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  #name    = "ccms-ebs-app${count.index + 1}.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_ebsapps[count.index].private_ip]
}

## PROD EBSAPPS
resource "aws_route53_record" "prod_ebsapps" {
  provider = aws.core-network-services
  count    = local.is-production ? local.application_data.accounts[local.environment].ebsapps_no_instances : 0
  zone_id  = data.aws_route53_zone.prod-network-services.zone_id
  name     = "ccms-ebs-app${count.index + 1}.ccms-ebs.service.justice.gov.uk"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.ec2_ebsapps[count.index].private_ip]
}

/*resource "aws_route53_record" "ebsapps_cname" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].ebsapps_no_instances

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "ccms-ebs-app${count.index + 1}"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.ebsapps[count.index].fqdn]
}*/

## EBSWEBGATE
resource "aws_route53_record" "ebswgate" {
  #count    = (local.environment == "development" || local.environment == "test") ? 1 : 0
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  //  count    = local.application_data.accounts[local.environment].webgate_no_instances
  name = "portal-ag.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  #name    = "wgate${local.application_data.accounts[local.environment].short_env}${count.index + 1}.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type = "A"
  alias {
    name                   = aws_lb.webgate_lb[count.index].dns_name
    zone_id                = aws_lb.webgate_lb[count.index].zone_id
    evaluate_target_health = false
  }
}

## PROD EBSWEBGATE
resource "aws_route53_record" "prod_ebswgate" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.prod-network-services.zone_id
  name     = "portal-ag.ccms-ebs.service.justice.gov.uk"
  type     = "A"
  alias {
    name                   = aws_lb.webgate_lb[count.index].dns_name
    zone_id                = aws_lb.webgate_lb[count.index].zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "webgate_ec2" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].webgate_no_instances

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${local.application_data.accounts[local.environment].webgate_dns_prefix}${count.index + 1}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  #name    = "ccms-ebs-app${count.index + 1}.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_webgate[count.index].private_ip]
}

# PROD WEBGATE INSTANCES
resource "aws_route53_record" "prod_webgate_ec2" {
  provider = aws.core-network-services
  count    = local.is-production ? local.application_data.accounts[local.environment].webgate_no_instances : 0
  zone_id  = data.aws_route53_zone.prod-network-services.zone_id
  name     = "${local.application_data.accounts[local.environment].webgate_dns_prefix}${count.index + 1}.ccms-ebs.service.justice.gov.uk"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.ec2_webgate[count.index].private_ip]
}

# resource "aws_route53_record" "webgate_ec2_single" {
#   provider = aws.core-vpc
#   count    = local.is-production || local.is-preproduction || local.is-development ? 0 : local.application_data.accounts[local.environment].webgate_no_instances
#   zone_id  = data.aws_route53_zone.external.zone_id
#   name     = "${local.application_data.accounts[local.environment].webgate_dns_prefix}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type     = "A"
#   ttl      = 300
#   records  = [aws_instance.ec2_webgate[count.index].private_ip]
# }

/*resource "aws_route53_record" "ebswgate_cname" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].webgate_no_instances

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "wgate${local.application_data.accounts[local.environment].short_env}${count.index + 1}"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.ebswgate[count.index].fqdn]
}*/

## EBSACCESSGATE
# resource "aws_route53_record" "ebsagate" {

#   provider = aws.core-vpc
#   count    = (local.environment == "preproduction" || local.environment == "production") ? 1 : local.application_data.accounts[local.environment].accessgate_no_instances
#   #count    = local.application_data.accounts[local.environment].accessgate_no_instances

#   zone_id = data.aws_route53_zone.external.zone_id
#   name    = "agate${local.application_data.accounts[local.environment].short_env}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   #name    = "agate${local.application_data.accounts[local.environment].short_env}${count.index + 1}.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type    = "A"
#   ttl     = 300
#   records = [aws_instance.ec2_accessgate[count.index].private_ip]
# }

resource "aws_route53_record" "accessgate_ec2" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].accessgate_no_instances

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${local.application_data.accounts[local.environment].accessgate_dns_prefix}${count.index + 1}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  #name    = "ccms-ebs-app${count.index + 1}.${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_accessgate[count.index].private_ip]
}

# PROD ACCESSGATE INSTANCES
resource "aws_route53_record" "prod_accessgate_ec2" {
  provider = aws.core-network-services
  count    = local.is-production ? local.application_data.accounts[local.environment].accessgate_no_instances : 0

  zone_id = data.aws_route53_zone.prod-network-services.zone_id
  name    = "${local.application_data.accounts[local.environment].accessgate_dns_prefix}${count.index + 1}.ccms-ebs.service.justice.gov.uk"
  type    = "A"
  ttl     = 300
  records = [aws_instance.ec2_accessgate[count.index].private_ip]
}

# resource "aws_route53_record" "accessgate_ec2_single" {
#   provider = aws.core-vpc
#   count    = local.is-production || local.is-preproduction || local.is-development ? 0 : local.application_data.accounts[local.environment].accessgate_no_instances
#   zone_id  = data.aws_route53_zone.external.zone_id
#   name     = "${local.application_data.accounts[local.environment].accessgate_dns_prefix}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
#   type     = "A"
#   ttl      = 300
#   records  = [aws_instance.ec2_accessgate[count.index].private_ip]
# }

/*resource "aws_route53_record" "ebsagate_cname" {
  provider = aws.core-vpc
  count    = local.application_data.accounts[local.environment].accessgate_no_instances

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "agate${local.application_data.accounts[local.environment].short_env}${count.index + 1}"
  ttl     = "300"
  type    = "CNAME"
  records = [aws_route53_record.ebsagate[count.index].fqdn]
}*/

## ClamAV
resource "aws_route53_record" "clamav" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "clamav.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.ec2_clamav.private_ip]
}

## PROD ClamAV
resource "aws_route53_record" "prod_clamav" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = data.aws_route53_zone.prod-network-services.zone_id
  name     = "clamav.ccms-ebs.service.justice.gov.uk"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.ec2_clamav.private_ip]
}

## FTP
resource "aws_route53_record" "ftp" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ftp.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type     = "A"
  ttl      = 300
  records  = [aws_instance.ec2_ftp.private_ip]
}