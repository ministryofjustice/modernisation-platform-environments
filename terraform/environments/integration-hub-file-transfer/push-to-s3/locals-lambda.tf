locals {
  pattern_name     = "${local.application_name}-${local.environment}-${local.component_name}"
  lambda_role_name = local.pattern_name
}