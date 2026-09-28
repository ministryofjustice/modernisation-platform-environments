
module "public_dns_zone" {
  source              = "./modules/dns/hosted_zone"
  domain_name         = local.application_data.accounts[local.environment].domain_name
  project_name        = local.project_name
  private_hosted_zone = false
  vpc                 = data.aws_vpc.shared.id
  tags                = local.tags
}

#used only for ses
module "justice_public_dns_zone" {
  source              = "./modules/dns/hosted_zone"
  domain_name         = local.application_data.accounts[local.environment].justice_domain_name
  project_name        = local.project_name
  private_hosted_zone = false
  vpc                 = data.aws_vpc.shared.id
  tags                = local.tags
}


locals {
  # Allow SES only where the zone's own SES identity is verified (dev/preprod), otherwise park it
  ses_sends_as_domain = try(local.application_data.accounts[local.environment].ses_domain_identities[local.application_data.accounts[local.environment].domain_name].create_records, false)
}

resource "aws_route53_record" "spf" {
  zone_id = module.public_dns_zone.aws_route53_zone_id
  name    = local.application_data.accounts[local.environment].domain_name
  type    = "TXT"
  ttl     = 300
  records = [local.ses_sends_as_domain ? "v=spf1 include:amazonses.com -all" : "v=spf1 -all"]
}

resource "aws_route53_record" "dmarc" {
  zone_id = module.public_dns_zone.aws_route53_zone_id
  name    = "_dmarc.${local.application_data.accounts[local.environment].domain_name}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=reject;"]
}
