# This data sources allows us to get the Modernisation Platform account information for use elsewhere
# (when we want to assume a role in the MP, for instance)
# data "aws_organizations_organization" "root_account" {}

# Get the environments file from the main repository
data "http" "environments_file" {
  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${local.application_name}.json"
}

data "github_team" "dso_users" {
  slug = "studio-webops"
}

# Get session information from OIDC provider
data "aws_caller_identity" "oidc_session" {
  provider = aws.oidc-session
}

# get shared subnet-set vpc object
data "aws_vpc" "shared_vpc" {
  # provider = aws.share-host
  tags = {
    Name = "${local.vpc_name}-${local.environment}"
  }
}

data "aws_kms_key" "general_shared" {
  key_id = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["core-shared-services-production"]}:alias/general-${var.networking[0].business-unit}"
  provider = aws.core-shared-services
}

data "aws_iam_session_context" "whoami" {
  provider = aws.oidc-session
  arn      = data.aws_caller_identity.oidc_session.arn
}

locals {

  # Stores modernisation platform account id for setting up the modernisation-platform provider
  secret_prefix = "/Jumpserver/Users"

  modernisation_platform_account_id = data.aws_ssm_parameter.modernisation_platform_account_id.value

  application_name = var.networking[0].application

  environment_management = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)

  # This takes the name of the Terraform workspace (e.g. core-vpc-production), strips out the application name (e.g. core-vpc), and checks if
  # the string leftover is `-production`, if it isn't (e.g. core-vpc-non-production => -non-production) then it sets the var to false.
  # tflint-ignore: terraform_unused_declarations
  is-production = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production"
  # tflint-ignore: terraform_unused_declarations
  is-preproduction = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-preproduction"
  # tflint-ignore: terraform_unused_declarations
  is-test = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-test"
  # tflint-ignore: terraform_unused_declarations
  is-development = substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-development"

  # Merge tags from the environment json file with additional ones
  # The environment file contains application, business-unit, infrastructure-support and owner tags
  tags = merge(
    jsondecode(data.http.environments_file.response_body).tags,
    { "is-production" = local.is-production },
    { "environment-name" = terraform.workspace },
    { "source-code" = "https://github.com/ministryofjustice/modernisation-platform-environments" }
  )

  environment = trimprefix(terraform.workspace, "${var.networking[0].application}-")
  vpc_name    = var.networking[0].business-unit
  vpc_id      = data.aws_vpc.shared_vpc.id
  subnet_set  = var.networking[0].set

  # tflint-ignore: terraform_unused_declarations
  is_live       = [substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-production" || substr(terraform.workspace, length(local.application_name), length(terraform.workspace)) == "-preproduction" ? "live" : "non-live"]
  provider_name = "core-vpc-${local.environment}"

  # environment specfic variables
  # example usage:
  # example_data = local.accounts[local.environment].example_var
  # application_data = jsondecode(file("./application_variables.json"))
  # application_data = fileexists("./application_variables.json") ? jsondecode(file("./application_variables.json")) : {}

  region            = "eu-west-2"
  availability_zone = "eu-west-2a"
}

# This account id
data "aws_caller_identity" "current" {}

# Infrastructure CICD role
data "aws_iam_role" "member_infrastructure_access" {
  name = "MemberInfrastructureAccess"
}

#------------------------------------------------------------------------------
# Route 53 Zones
#------------------------------------------------------------------------------
data "aws_route53_zone" "internal" {
  provider = aws.core-vpc

  name         = "${local.vpc_name}-${local.environment}.modernisation-platform.internal."
  private_zone = true
}

data "aws_route53_zone" "external" {
  provider = aws.core-network-services

  name         = "modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

data "aws_route53_zone" "external-environment" {
  provider = aws.core-vpc

  name         = "${local.vpc_name}-${local.environment}.modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

