module "acm_certificate" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  zone_id                   = module.route53_zones.route53_zone_zone_id[local.environment_configuration.route53_zone]
  domain_name               = local.environment_configuration.route53_zone
  subject_alternative_names = ["*.${local.environment_configuration.route53_zone}"]

  validation_method = "DNS"

  tags = local.tags
}
