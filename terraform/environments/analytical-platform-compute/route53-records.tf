module "route53_records" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "4.1.0"

  zone_id = module.route53_zones.route53_zone_zone_id[local.environment_configuration.route53_zone]

  records = [
    {
      name    = "airflow"
      type    = "CNAME"
      ttl     = 300
      records = [module.mwaa_alb.dns_name]
    }
  ]
}
