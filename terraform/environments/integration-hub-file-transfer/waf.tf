module "waf_web_app" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  providers = { aws = aws.us-east-1 }
  source    = "terraform-aws-modules/wafv2/aws"
  version   = "2.1.0"

  name           = "${local.application_name}-${local.environment}-web"
  scope          = "CLOUDFRONT"
  default_action = "allow"

  rules = merge({
    rate-limit = {
      priority = 0
      action   = "block"
      statement = {
        rate_based_statement = {
          aggregate_key_type    = "IP"
          evaluation_window_sec = 300
          limit                 = 2000
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.application_name}-${local.environment}-web-rate-limit"
        sampled_requests_enabled   = false
      }
    }
    }, {
    for name, priority in local.transfer_web_app_managed_rules : name => {
      priority        = priority
      override_action = "count"
      statement = {
        managed_rule_group_statement = {
          name        = name
          vendor_name = "AWS"
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.application_name}-${local.environment}-${name}"
        sampled_requests_enabled   = false
      }
    }
  })

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.application_name}-${local.environment}-web"
    sampled_requests_enabled   = false
  }

  create_logging_configuration    = true
  logging_log_destination_configs = [module.cloudwatch_web_app["waf"].cloudwatch_log_group_arn]
  logging_redacted_fields = [
    { single_header = { name = "authorization" } },
    { single_header = { name = "cookie" } },
    { single_header = { name = "referer" } },
    { single_header = { name = "x-amz-security-token" } },
    { query_string = {} },
  ]

  tags = local.tags
}