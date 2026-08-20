module "acm_certificate" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.0"

  zone_id                   = module.route53_zone.id
  domain_name               = local.environment_configuration.route53_zone
  subject_alternative_names = ["*.${local.environment_configuration.route53_zone}"]

  validation_method = "DNS"

  tags = local.tags
}
