data "aws_lb" "app" {
  name = local.component_name

  depends_on = [helm_release.app_configuration]
}

module "waf_app_log_group" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git//modules/log-group?ref=a2a5f9d15e30d0d24b667933599e5e1bef24a8b8" # v5.7.2

  name              = "aws-waf-logs-${local.component_name}"
  retention_in_days = 365
}

module "waf_ip_set_app_allowlist" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-wafv2.git//modules/ip-set?ref=36eceb918a237a80b69ce98e50b6f83fe17d2401" # v2.1.0

  name               = "${local.component_name}-allowlist-${local.environment}"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = local.environment_configuration.app_ingress_allowlist
}

module "waf_app" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-wafv2.git?ref=36eceb918a237a80b69ce98e50b6f83fe17d2401" # v2.1.0

  name  = "${local.component_name}-${local.environment}"
  scope = "REGIONAL"

  default_action = "block"

  association_resource_arns = {
    alb = data.aws_lb.app.arn
  }

  rules = {
    ip-allowlist = {
      priority = 0
      action   = "allow"

      statement = {
        ip_set_reference_statement = {
          arn = module.waf_ip_set_app_allowlist.arn
        }
      }

      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "${local.component_name}-ip-allowlist"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.component_name}-waf"
    sampled_requests_enabled   = true
  }

  create_logging_configuration    = true
  logging_log_destination_configs = [module.waf_app_log_group.cloudwatch_log_group_arn]
}
