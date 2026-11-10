# Majority of resources created by baseline module.
# See common settings in locals.tf and environment specific settings in
# locals_development.tf, locals_test.tf etc.

module "ip_addresses" {
  source = "../../modules/ip_addresses"
}

module "environment" {
  source = "../../modules/environment"

  providers = {
    aws.modernisation-platform = aws.modernisation-platform
    aws.core-network-services  = aws.core-network-services
    aws.core-vpc               = aws.core-vpc
  }

  environment_management = local.environment_management
  business_unit          = var.networking[0].business-unit
  application_name       = local.application_name
  environment            = local.environment
  subnet_set             = local.subnet_set
}

module "baseline_presets" {
  source = "../../modules/baseline_presets"

  environment  = module.environment
  ip_addresses = module.ip_addresses

  options = merge(
    local.baseline_presets_all_environments.options,
    local.baseline_presets_environment_specific.options
  )
}

module "baseline" {
  source = "../../modules/baseline"

  providers = {
    aws                       = aws
    aws.core-network-services = aws.core-network-services
    aws.core-vpc              = aws.core-vpc
    aws.us-east-1             = aws.us-east-1
  }

  environment = module.environment

  cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms_baseline,
    lookup(local.baseline_all_environments, "cloudwatch_metric_alarms", {}),
    lookup(local.baseline_environment_specific, "cloudwatch_metric_alarms", {}),
  )

  sns_topics = merge(
    module.baseline_presets.sns_topics,
    lookup(local.baseline_all_environments, "sns_topics", {}),
    lookup(local.baseline_environment_specific, "sns_topics", {}),
  )
}

module "github_workflow_scheduler" {
  source                     = "../../modules/github_lambda"
  aws_account_id             = data.aws_caller_identity.current.id
  enable_outbound_federation = local.github_actions_lambda_environment_specific.enable_outbound_federation
  project_name               = local.github_actions_project_name
  github_workflows           = local.github_actions_lambda_environment_specific.github_workflows
}

resource "aws_ssm_parameter" "aws_health_lambda_accounts" {
  count       = local.enable_aws_health_lambda ? 1 : 0
  name        = "health_lambda_accounts"
  description = "AWS Health Lambda accounts"
  type        = "SecureString"
  value       = "TO_BE_UPDATED"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "aws_health_lambda_ignore_findings" {
  count       = local.enable_aws_health_lambda ? 1 : 0
  name        = "health_lambda_ignore_findings"
  description = "AWS Health Lambda ignore findings"
  type        = "SecureString"
  value       = "TO_BE_UPDATED"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

module "aws_health_lambda" {
  count                          = local.enable_aws_health_lambda ? 1 : 0
  source                         = "../../modules/aws_health_lambda"
  aws_account_id                 = data.aws_caller_identity.current.id
  aws_accounts_parameter_name    = aws_ssm_parameter.aws_health_lambda_accounts[count.index].name
  github_repo                    = "platform-operations"
  ignore_findings_parameter_name = aws_ssm_parameter.aws_health_lambda_ignore_findings[count.index].name
}

resource "aws_ssm_parameter" "aws_securityhub_lambda" {
  for_each = local.enable_aws_securityhub_lambda ? {
    accounts = {
      name        = "securityhub_lambda_accounts"
      description = "AWS SecurityHub Lambda accounts"
    }
    ignore_findings = {
      name        = "securityhub_lambda_ignore_findings"
      description = "AWS SecurityHub Lambda ignore findings"
    }
  } : {}

  name        = each.value.name
  description = each.value.description
  type        = "SecureString"
  value       = "TO_BE_UPDATED"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

module "aws_securityhub_lambda" {
  count                                      = local.enable_aws_securityhub_lambda ? 1 : 0
  source                                     = "../../modules/aws_securityhub_lambda"
  aws_account_id                             = data.aws_caller_identity.current.id
  aws_accounts_parameter_name                = aws_ssm_parameter.aws_securityhub_lambda["accounts"].name
  github_repo                                = "platform-operations"
  securityhub_ignore_findings_parameter_name = aws_ssm_parameter.aws_securityhub_lambda["ignore_findings"].name
  depends_on                                 = [aws_ssm_parameter.aws_securityhub_lambda]
}
