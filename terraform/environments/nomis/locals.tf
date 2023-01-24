locals {
  business_unit    = var.networking[0].business-unit
  application_name = var.networking[0].application
  environment      = trimprefix(terraform.workspace, "${var.networking[0].application}-")
  subnet_set       = var.networking[0].set
}

locals {
  modernisation_platform_account_id = data.aws_ssm_parameter.modernisation_platform_account_id.value
  environment_management            = jsondecode(data.aws_secretsmanager_secret_version.environment_management.secret_string)
}



data "github_team" "dso_users" {
  slug = "studio-webops"
}

# Get session information from OIDC provider
data "aws_caller_identity" "oidc_session" {
  provider = aws.oidc-session
}

data "aws_iam_session_context" "whoami" {
  provider = aws.oidc-session
  arn      = data.aws_caller_identity.oidc_session.arn
}

locals {

  # Stores modernisation platform account id for setting up the modernisation-platform provider
  secret_prefix = "/Jumpserver/Users"


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

  tags = module.environment.tags


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

  autoscaling_schedules_default = {
    "scale_up" = {
      recurrence = "0 7 * * Mon-Fri"
    }
    "scale_down" = {
      desired_capacity = 0
      recurrence       = "0 19 * * Mon-Fri"
    }
  }
}

# This account id
data "aws_caller_identity" "current" {}

# Infrastructure CICD role
data "aws_iam_role" "member_infrastructure_access" {
  name = "MemberInfrastructureAccess"
}
