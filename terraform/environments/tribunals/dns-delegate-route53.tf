locals {

  ec2_records = [
    "decisions",
    "asylumsupport.decisions",
    "adminappeals.reports",
    "charity.decisions",
    "claimsmanagement.decisions",
    "consumercreditappeals.decisions",
    "estateagentappeals.decisions",
    "phl.decisions",
    "sscs.venues",
    "siac.decisions",
    "taxandchancery_ut.decisions",
    "tax.decisions"
  ]

  afd_records = [
    "administrativeappeals.decisions",
    "carestandards.decisions",
    "cicap.decisions",
    "employmentappeals.decisions",
    "financeandtax.decisions",
    "immigrationservices.decisions",
    "informationrights.decisions",
    "landregistrationdivision.decisions", 
    "landschamber.decisions",
    "transportappeals.decisions"
  ]

  afd_records_migrated = [
    "cicap.decisions"
  ]

  nginx_records = [
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

# 'CNAME' records for all www legacy services which currently route through Azure Front Door
resource "aws_route53_record" "afd_instances" {
  count    = local.is-production ? length(local.afd_records) : 0
  provider = aws.core-network-services
  zone_id  = local.production_zone_id
  name     = local.afd_records[count.index]
  type     = "CNAME"
  ttl      = 300
  records  = ["sdshmcts-prod-egd0dscwgwh0bpdq.z01.azurefd.net"]
}

# 'CNAME' records for all www legacy services which have been migrated to the Modernisation Platform
resource "aws_route53_record" "afd_instances_migrated" {
  count    = local.is-production ? length(local.afd_records_migrated) : 0
  provider = aws.core-network-services
  zone_id  = local.production_zone_id
  name     = local.afd_records_migrated[count.index]
  type     = "CNAME"
  ttl      = 300
  records  = [aws_lb.tribunals_lb.dns_name]
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
    name                   = "tribunals-nginx-1184258455.eu-west-1.elb.amazonaws.com."
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

# TXT validation record
resource "aws_route53_record" "txt_instance" {
  count    = local.is-production ? 1 : 0
  provider = aws.core-network-services
  zone_id  = local.production_zone_id
  name     = "_asvdns-5429b53c-d07b-4d04-83ea-9df3ff2bcdc0.tribunals.gov.uk"
  type     = "TXT"
  ttl      = 300
  records  = ["asvdns_7665450b-1d2a-41de-a8b7-c7a89c63c6b5"]
}