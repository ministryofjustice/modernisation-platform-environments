locals {

  application_name = "analytical-platform-ingestion"
  component_name   = "dms"

  environment_management = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)

  # Stores modernisation platform account id for setting up the modernisation-platform provider
  modernisation_platform_account_id = data.aws_ssm_parameter.modernisation_platform_account_id.value

  # This takes the name of the Terraform workspace (e.g. core-vpc-production), strips out the application name (e.g. core-vpc), and checks if
  # the string leftover is `-production`, if it isn't (e.g. core-vpc-non-production => -non-production) then it sets the var to false.
  is-production    = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production"
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
  kms_key_id      = module.dms_kms_source_cmk.key_id
  # set aws_dms_endpoint    = aws_dms_endpoint.source
  # set aws_dms_s3_endpoint = aws_dms_s3_endpoint.target
  project_id      = var.networking[0].project-id
  short_name      = var.networking[0].short-name

  db_creds_source = jsondecode(aws_secretsmanager_secret_version.resource_dms_secret_current.secret_string)


  is_live       = [substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production" || substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-preproduction" ? "live" : "non-live"]
  provider_name = "core-vpc-${local.environment}"


  # environment specfic variables
  # example usage:
  # example_data = local.application_data.accounts[local.environment].example_var
  
  # originally application data json file was referenced at teh root of the repo  as below:


  #application_data = fileexists("./application_variables.json") ? jsondecode(file("./application_variables.json")) : null

  application_data = fileexists("application_variables.json") ? jsondecode(file("application_variables.json")) : null
  environment_configurations = jsondecode(file("../environment-configuration.tf"))
}

}
