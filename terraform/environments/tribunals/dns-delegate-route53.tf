locals {

  ec2_records = [
    "decisions",
    "asylumsupport.decisions"
  ]

  ec2_records_migrated = [
    "adminappeals.reports",
    "claimsmanagement.decisions",
    "sscs.venues",
    "tax.decisions",
    "consumercreditappeals.decisions",
    "estateagentappeals.decisions",
    "siac.decisions",
    "taxandchancery_ut.decisions",
    "charity.decisions",
    "phl.decisions"
  ]

  afd_records_migrated = [
    "administrativeappeals.decisions",
    "cicap.decisions",
    "carestandards.decisions",
    "employmentappeals.decisions",
    "informationrights.decisions",
    "immigrationservices.decisions",
    "financeandtax.decisions",
    "landregistrationdivision.decisions",
    "landschamber.decisions",
    "transportappeals.decisions"
  ]

  nginx_records = [
  ]

  nginx_records_pre_migration = [
    "",
    "adjudicationpanel",
    "charity",
    "consumercreditappeals",
    "estateagentappeals",
    "fhsaa",
    "siac"
  ]

  www_records = [
    "www.adjudicationpanel",
    "www.charity",
    "www.consumercreditappeals",
    "www.estateagentappeals",
    "www.fhsaa",
    "www.siac"
  ]

  production_zone_id = data.aws_route53_zone.production_zone.zone_id
}

# 'A' records for sftp services currently routed to the existing EC2 Tribunals instance in DSD account via static ip address
resource "aws_route53_record" "ec2_instances" {
  count    = local.is-production ? length(local.ec2_records) : 0
  provider = aws.core-network-services
  zone_id  = local.production_zone_id
  name     = local.ec2_records[count.index]
  type     = "A"
  ttl      = 300
  records  = ["34.243.192.28"]
}

resource "aws_route53_record" "ec2_instances_migrated" {
  count    = local.is-production ? length(local.ec2_records_migrated) : 0
  provider = aws.core-network-services
  zone_id  = local.production_zone_id
  name     = local.ec2_records_migrated[count.index]
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.tribunals_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.tribunals_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "sftp_external_services_prod" {
  count           = local.is-production ? length(local.ec2_records_migrated) : 0
  allow_overwrite = true
  provider        = aws.core-network-services
  zone_id         = local.production_zone_id
  name            = "sftp.${local.ec2_records_migrated[count.index]}"
  type            = "CNAME"
  records         = [aws_lb.tribunals_lb_sftp.dns_name]
  ttl             = 60
}

# 'CNAME' records for all www legacy services which have been migrated to the Modernisation Platform
resource "aws_route53_record" "afd_instances_migrated" {
  count    = local.is-production ? length(local.afd_records_migrated) : 0
  provider = aws.core-network-services
  zone_id  = local.production_zone_id
  name     = local.afd_records_migrated[count.index]
  type     = "CNAME"
  ttl      = 300
  records  = [aws_cloudfront_distribution.tribunals_distribution.domain_name]
}

# 'A' records for tribunals URLs routed through the NGINX reverse proxy hosted in AWS DSD Account
# This includes the empty name for the root domain
# The target ALB is in eu-west-1 zone which has a fixed zone id of "Z32O12XQLNTSW2"
resource "aws_route53_record" "nginx_instances" {
  count    = local.is-production ? length(local.nginx_records) : 0
  provider = aws.core-network-services
  zone_id  = local.production_zone_id
  name     = local.nginx_records[count.index]
  type     = "A"

  alias {
    name                   = module.nginx_load_balancer[0].nginx_lb_arn
    zone_id                = module.nginx_load_balancer[0].nginx_lb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "nginx_instances_pre_migration" {
  count    = local.is-production ? length(local.nginx_records_pre_migration) : 0
  provider = aws.core-network-services
  zone_id  = local.production_zone_id
  name     = local.nginx_records_pre_migration[count.index]
  type     = "A"

  alias {
    name                   = "tribunals-nginx-1184258455.eu-west-1.elb.amazonaws.com"
    zone_id                = "Z32O12XQLNTSW2"
    evaluate_target_health = false
  }
}

# 'A' records for tribunals www. URLs redirects to existing entries - subtract the "www."
resource "aws_route53_record" "www_instances" {
  count    = local.is-production ? length(local.www_records) : 0
  provider = aws.core-network-services
  zone_id  = local.production_zone_id
  name     = local.www_records[count.index]
  type     = "A"

  alias {
    name                   = format("%s.tribunals.gov.uk", substr(local.www_records[count.index], 4, -1))
    zone_id                = local.production_zone_id
    evaluate_target_health = false
  }
}

#  The root www resource record needs its own resource to avoid breaking the logic of using the substring in www_instances
resource "aws_route53_record" "www_root" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = local.production_zone_id
  name     = "www"
  type     = "A"

  alias {
    name                   = "tribunals.gov.uk"
    zone_id                = local.production_zone_id
    evaluate_target_health = false
  }
}

# TXT validation records
resource "aws_route53_record" "txt_instance" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = local.production_zone_id
  name     = "_asvdns-5429b53c-d07b-4d04-83ea-9df3ff2bcdc0.tribunals.gov.uk"
  type     = "TXT"
  ttl      = 300
  records  = ["asvdns_7665450b-1d2a-41de-a8b7-c7a89c63c6b5"]
}

resource "aws_route53_record" "txt_instance_2" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = local.production_zone_id
  name     = "_dmarc.tribunals.gov.uk"
  type     = "TXT"
  ttl      = 300
  records  = ["v=DMARC1\\;p=reject\\;sp=reject\\;rua=mailto:dmarc-rua@dmarc.service.gov.uk\\;"]
}