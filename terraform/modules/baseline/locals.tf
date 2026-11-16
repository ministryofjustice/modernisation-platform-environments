locals {
  baseline_enable_aws_health_lambda      = (var.aws_health_lambda_configuration.enabled)
  baseline_enable_aws_securityhub_lambda = (var.aws_securityhub_lambda_configuration.enabled)
  tags                                   = merge(var.environment.tags, var.tags)
}
