locals {
  application_name          = "integration-hub"
  resource_application_name = "integration-hub-downstream-mock-api"
  component_name            = "service"
  resource_name_prefix      = local.resource_application_name
  workspace_application_prefixes = [
    "${local.application_name}-",
    "${local.resource_application_name}-",
  ]
  workspace_environment_matches = [
    for prefix in local.workspace_application_prefixes : trimprefix(terraform.workspace, prefix)
    if startswith(terraform.workspace, prefix)
  ]
  environment_name = length(local.workspace_environment_matches) > 0 ? local.workspace_environment_matches[0] : terraform.workspace

  environment_management            = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)
  modernisation_platform_account_id = data.aws_ssm_parameter.modernisation_platform_account_id.value

  is-production    = local.environment_name == "production"
  is-preproduction = local.environment_name == "preproduction"
  is-test          = local.environment_name == "test"
  is-development   = local.environment_name == "development"

  tags = merge(
    jsondecode(data.http.environments_file.response_body).tags,
    { "is-production" = local.is-production },
    { "environment-name" = terraform.workspace },
    { "source-code" = "https://github.com/ministryofjustice/modernisation-platform-environments" }
  )

  environment     = local.environment_name
  vpc_name        = var.networking[0].business-unit
  subnet_set      = var.networking[0].set
  vpc_all         = "${local.vpc_name}-${local.environment}"
  subnet_set_name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}"

  is_live          = [local.is-production || local.is-preproduction ? "live" : "non-live"]
  provider_name    = "core-vpc-${local.environment}"
  application_data = fileexists("./application_variables.json") ? jsondecode(file("./application_variables.json")) : null
}
