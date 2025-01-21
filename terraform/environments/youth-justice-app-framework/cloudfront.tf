
module "cloudfront" {
  source = "./modules/cloudfront"

  cloudfront_alias = "yjaf.${local.environment}.yjbservices.yjb.gov.uk"
  alb_dns          = module.external_alb.dns_name
  waf_web_acl_arn  = module.waf-cf.waf_arn
  r53_zone_id      = module.public_dns_zone.aws_route53_zone_id
  environment      = local.environment
  project_name     = local.project_name
  tags             = local.tags
}
