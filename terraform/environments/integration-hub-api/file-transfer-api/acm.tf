module "acm_api" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.1"

  domain_name             = local.acm_domains.api
  validation_method       = "DNS"
  key_algorithm           = "RSA_2048"
  create_route53_records  = false
  validation_record_fqdns = module.acm_api_validation[local.acm_domains.api].validation_route53_record_fqdns
}

module "acm_api_validation" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.1"

  for_each  = toset([local.acm_domains.api])
  providers = { aws = aws.core-network-services }

  create_certificate                        = false
  create_route53_records_only               = true
  validation_method                         = "DNS"
  distinct_domain_names                     = [each.key]
  zone_id                                   = data.aws_route53_zone.file_transfer.zone_id
  dns_ttl                                   = 60
  validation_allow_overwrite_records        = true
  acm_certificate_domain_validation_options = module.acm_api.acm_certificate_domain_validation_options
}
