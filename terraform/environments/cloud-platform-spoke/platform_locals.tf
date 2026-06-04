locals {

  application_name = "cloud-platform-spoke"

  environment_management = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)

  # Stores modernisation platform account id for setting up the modernisation-platform provider
  modernisation_platform_account_id = data.aws_ssm_parameter.modernisation_platform_account_id.value

  # Environment detection from workspace name
  is-production    = can(regex("-(production|live|nonlive)$", terraform.workspace))
  is-preproduction = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-preproduction"
  is-test          = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-test"
  is-development   = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-development"

  # Merge tags from the environment json file with additional ones
  tags = merge(
    jsondecode(data.http.environments_file.response_body).tags,
    { "is-production" = local.is-production },
    { "environment-name" = terraform.workspace },
    { "source-code" = "https://github.com/ministryofjustice/modernisation-platform-environments" }
  )

  environment     = trimprefix(terraform.workspace, "${var.networking[0].application}-")
  vpc_name        = var.networking[0].business-unit
  subnet_set      = var.networking[0].set
  vpc_all         = "${local.vpc_name}-${local.environment}"
  subnet_set_name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}"

  is_live       = [substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production" || substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-preproduction" ? "live" : "non-live"]
  provider_name = "core-vpc-${local.environment}"

  # Environment specific variables
  application_data = fileexists("./application_variables.json") ? jsondecode(file("./application_variables.json")) : null
}
