
module "waf-cf" {
  source      = "./modules/waf"
  kms_key_arn = module.kms.key_arn
  kms_key_id  = module.kms.key_id
  #  multi_region_replica = aws_kms_replica_key.multi_region_replica.arn # WAF multi-region key
  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }

  waf_IP_rules_cf = {
    "whitelist-ip-cf" = {
      name         = "whitelist-ip-cf"
      priority     = 2
      description  = "Whitelisted IP addresses"
      ip_addresses = ["66.103.29.115/32"]
    }
  }

  waf_header_allow_rules_cf = {
    "allow-malware-notifier" = {
      name     = "allow-malware-notifier"
      priority = 1
      paths = [
        "/secure/api/v1/auth",
        "/secure/api/v1/docs/threatDetected"
      ]
    }
  }
  waf_header_allow_header_name  = "X-Internal-Service"
  waf_header_allow_header_value = local.internal_service_token

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

