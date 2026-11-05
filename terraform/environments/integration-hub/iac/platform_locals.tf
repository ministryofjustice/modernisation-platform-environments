locals {
  application_name = "integration-hub"
  component_name   = "iac"

  environment_management = jsondecode(
    ephemeral.aws_secretsmanager_secret_version.environment_management.secret_string
  )
  modernisation_platform_account_id = data.aws_ssm_parameter.modernisation_platform_account_id.value

  is-production = terraform.workspace == "${local.application_name}-production"

  tags = merge(
    jsondecode(data.http.environments_file.response_body).tags,
    { "is-production" = local.is-production },
    { "environment-name" = terraform.workspace },
    { "source-code" = "https://github.com/ministryofjustice/modernisation-platform-environments" }
  )

  environment = trimprefix(terraform.workspace, "${local.application_name}-")
  account_id  = data.aws_caller_identity.current.account_id

  pagerduty_state_bucket_name = "integration-hub-production-pagerduty-tfstate"
  pagerduty_state_key         = "pagerduty/terraform.tfstate"
  pagerduty_secret_name       = "pagerduty/api-key"
  pagerduty_role_name         = "integration-hub-pagerduty"
  pagerduty_oidc_subject      = "repo:ministryofjustice/integration-hub:environment:pagerduty-production"
}
