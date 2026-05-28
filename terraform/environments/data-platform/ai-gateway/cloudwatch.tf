# AWS WAF requires log group names to start with aws-waf-logs-
module "waf_ai_gateway_log_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/log-group?ref=a2a5f9d15e30d0d24b667933599e5e1bef24a8b8" # v5.7.2

  name              = "aws-waf-logs-${local.component_name}-${local.environment}"
  retention_in_days = 90
}
