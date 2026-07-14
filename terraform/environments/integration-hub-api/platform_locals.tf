locals {

  application_name          = "integration-hub"
  resource_application_name = "integration-hub"
  component_name            = "api-platform"
  resource_name_prefix      = "${local.resource_application_name}-${local.component_name}"
  workspace_application_prefixes = [
    "integration-hub-api-",
    "${local.resource_application_name}-",
  ]
  workspace_environment_matches = [
    for prefix in local.workspace_application_prefixes : trimprefix(terraform.workspace, prefix)
    if startswith(terraform.workspace, prefix)
  ]
  environment_name = length(local.workspace_environment_matches) > 0 ? local.workspace_environment_matches[0] : terraform.workspace

  environment_management = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)

  # Stores modernisation platform account id for setting up the modernisation-platform provider
  modernisation_platform_account_id = data.aws_ssm_parameter.modernisation_platform_account_id.value

  # This takes the name of the Terraform workspace (e.g. core-vpc-production), strips out the application name (e.g. core-vpc), and checks if
  # the string leftover is `-production`, if it isn't (e.g. core-vpc-non-production => -non-production) then it sets the var to false.
  is-production    = local.environment_name == "production"
  is-preproduction = local.environment_name == "preproduction"
  is-test          = local.environment_name == "test"
  is-development   = local.environment_name == "development"

  # Merge tags from the environment json file with additional ones
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

  is_live       = [local.is-production || local.is-preproduction ? "live" : "non-live"]
  provider_name = "core-vpc-${local.environment}"

  # environment specfic variables
  # example usage:
  # example_data = local.application_data.accounts[local.environment].example_var
  application_data = fileexists("./application_variables.json") ? jsondecode(file("./application_variables.json")) : null
}
