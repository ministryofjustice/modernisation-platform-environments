module "waf-cf" {
  source = "./modules/waf"
  providers = {
    aws = aws.us-east-1
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
        country_codes = ["GB", "FR"]
      }
    }
  ]
}
