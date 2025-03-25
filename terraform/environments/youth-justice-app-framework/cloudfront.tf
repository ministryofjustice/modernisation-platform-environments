module "cloudfront_yjaf" {
  source = "./modules/cloudfront"

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }

  cloudfront_alias               = "yjaf.${local.environment}.yjbservices.yjb.gov.uk"
  alb_dns                        = module.external_alb.dns_name
  waf_web_acl_arn                = module.waf-cf.waf_arn
  r53_zone_id                    = module.public_dns_zone.aws_route53_zone_id
  cloudfront_route53_record_name = "yjaf"
  kms_key_arn                    = module.kms.key_arn
  environment                    = local.environment
  project_name                   = local.project_name
  tags                           = local.tags
}
