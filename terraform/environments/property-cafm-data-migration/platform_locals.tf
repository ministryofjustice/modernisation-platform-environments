locals {

  application_name = "property-cafm-data-migration"

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
  application_data = fileexists("./application_variables.json") ? jsondecode(file("./application_variables.json")) : null

  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets    = cidrsubnets(local.application_data.accounts[local.environment].vpc_cidr, 4, 4, 4)
}

locals {  
  sftp_users_all = {
    "dev_user1" = {
      environment  = "development"
      user_name    = "dev_user1"
      s3_bucket    = aws_s3_bucket.CAFM.bucket
      ssm_key_name = "/sftp/keys/dev_user1"
    }
    "dev_user2" = {
      environment  = "development"
      user_name    = "dev_user2"
      s3_bucket    = aws_s3_bucket.CAFM.bucket
      ssm_key_name = "/sftp/keys/dev_user2"
    }
  }

  # Filter only users matching the current environment
  sftp_users = {
    for username, config in local.sftp_users_all :
    username => config
    if config.environment == local.environment
  }
}