module "waf_ai_gateway_log_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/log-group?ref=a2a5f9d15e30d0d24b667933599e5e1bef24a8b8" # v5.7.2

  name              = "aws-waf-logs-${local.component_name}"
  retention_in_days = 365
  kms_key_id        = module.ai_gateway_cloudwatch_kms_key.key_arn
}
