# This data sources allows us to get the Modernisation Platform account information for use elsewhere
# (when we want to assume a role in the MP, for instance)
data "aws_organizations_organization" "root_account" {}

# Get the environments file from the main repository
data "http" "environments_file" {
  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${local.application_name}.json"
}

data "aws_caller_identity" "oidc_session" {
  provider = aws.oidc-session
}

data "aws_caller_identity" "modernisation_platform" {
  provider = aws.modernisation-platform
}

locals {

  application_name = "oasys"

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

  is_live       = [substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production" || substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-preproduction" ? "live" : "non-live"]
  provider_name = "core-vpc-${local.environment}"

  # environment specfic variables
  # example usage:
  # example_data = local.application_data.accounts[local.environment].example_var
  application_data = fileexists("./application_variables.json") ? jsondecode(file("./application_variables.json")) : {}

  cidrs = { # this list should be abstracted for multiple environments to use
    # Azure
    noms_live                  = "10.40.0.0/18"
    noms_live_dr               = "10.40.64.0/18"
    noms_mgmt_live             = "10.40.128.0/20"
    noms_mgmt_live_dr          = "10.40.144.0/20"
    noms_transit_live          = "10.40.160.0/20"
    noms_transit_live_dr       = "10.40.176.0/20"
    noms_test                  = "10.101.0.0/16"
    noms_mgmt                  = "10.102.0.0/16"
    noms_test_dr               = "10.111.0.0/16"
    noms_mgmt_dr               = "10.112.0.0/16"
    aks_studio_hosting_live_1  = "10.244.0.0/20"
    aks_studio_hosting_dev_1   = "10.247.0.0/20"
    aks_studio_hosting_ops_1   = "10.247.32.0/20"
    nomisapi_t2_root_vnet      = "10.47.0.192/26"
    nomisapi_t3_root_vnet      = "10.47.0.0/26"
    nomisapi_preprod_root_vnet = "10.47.0.64/26"
    nomisapi_prod_root_vnet    = "10.47.0.128/26"

    # AWS
    cloud_platform = "172.20.0.0/16"
  }
}
