# tflint-ignore: terraform_deprecated_interpolation
module "route53_zones" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "2.11.1"

  zones = {
    "${local.environment_configuration.route53_zone}" = {
      comment = local.environment_configuration.route53_zone
    }
  }

  tags = local.tags
}
