data "aws_route53_zone" "service" {
  provider     = aws.core-network-services
  name         = local.is-production == false ? "${local.environment}.file-transfer.service.justice.gov.uk" : "file-transfer.service.justice.gov.uk"
  private_zone = false
}

module "acm_ftps" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.1"

  domain_name             = local.acm_domains.ftps
  validation_method       = "DNS"
  key_algorithm           = "RSA_2048"
  create_route53_records  = false
  validation_record_fqdns = module.acm_ftps_validation[local.acm_domains.ftps].validation_route53_record_fqdns
}

module "acm_ftps_validation" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.1"

  for_each  = toset([local.acm_domains.ftps])
  providers = { aws = aws.core-network-services }

  create_certificate                        = false
  create_route53_records_only               = true
  validation_method                         = "DNS"
  distinct_domain_names                     = [each.key]
  zone_id                                   = module.r53_file_transfer.id
  dns_ttl                                   = 60
  validation_allow_overwrite_records        = true
  acm_certificate_domain_validation_options = module.acm_ftps.acm_certificate_domain_validation_options
}

module "acm_web_app" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.1"

  region                  = "us-east-1"
  domain_name             = local.acm_domains.web_app
  validation_method       = "DNS"
  key_algorithm           = "RSA_2048"
  create_route53_records  = false
  validation_record_fqdns = module.acm_web_app_validation[local.acm_domains.web_app].validation_route53_record_fqdns
}

module "acm_web_app_validation" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.1"

  for_each  = toset([local.acm_domains.web_app])
  providers = { aws = aws.core-network-services }

  create_certificate                        = false
  create_route53_records_only               = true
  validation_method                         = "DNS"
  distinct_domain_names                     = [each.key]
  zone_id                                   = data.aws_route53_zone.service.zone_id
  dns_ttl                                   = 60
  validation_allow_overwrite_records        = true
  acm_certificate_domain_validation_options = module.acm_web_app.acm_certificate_domain_validation_options
}