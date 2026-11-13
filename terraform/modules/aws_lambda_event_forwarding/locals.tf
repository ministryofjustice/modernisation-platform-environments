locals {
  enable_aws_health_lambda      = (var.aws_health_lambda_configuration.enabled)
  enable_aws_securityhub_lambda = (var.aws_securityhub_lambda_configuration.enabled)
}