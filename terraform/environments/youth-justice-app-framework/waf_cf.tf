
module "waf-cf" {
  source             = "./modules/waf"
  kms_key_arn        = module.kms.key_arn
  kms_key_id         = module.kms.key_id
  kms_key_us_east_1  = aws_kms_key.multi_region_waf_key.arn # WAF multi-region key
  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }

  project_name = local.project_name
  tags         = local.tags
  waf_name     = "yjaf-cf"
  scope        = "CLOUDFRONT"
  waf_geoIP_rules = [
    {
      name     = "GeoIP"
      priority = 3
      geo_match_statement = {
        country_codes = ["GB", "FR", "IE"]
      }
    }
  ]
}

