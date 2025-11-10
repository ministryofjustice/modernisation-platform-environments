# Get modernisation account id from ssm parameter
data "aws_ssm_parameter" "modernisation_platform_account_id" {
  provider = aws.original-session
  name     = "modernisation_platform_account_id"
}

# Get secret by arn for environment management
data "aws_secretsmanager_secret" "environment_management" {
  provider = aws.modernisation-platform
  name     = "environment_management"
}

# Get latest secret value with ID from above. This secret stores account IDs for the Modernisation Platform sub-accounts
data "aws_secretsmanager_secret_version" "environment_management" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.environment_management.id
}

# Klayers Account ID - used by lambda layer ARNs - https://github.com/keithrozario/Klayers?tab=readme-ov-file
data "aws_ssm_parameter" "klayers_account_dev" {
  count           = local.is-development == true ? 1 : 0
  name            = "klayers-account"
  with_decryption = true
}

# Klayers Account ID - used by lambda layer ARNs - https://github.com/keithrozario/Klayers?tab=readme-ov-file
data "aws_ssm_parameter" "klayers_account_uat" {
  count           = local.is-preproduction == true ? 1 : 0
  name            = "klayers-account"
  with_decryption = true
}

# Klayers Account ID - used by lambda layer ARNs - https://github.com/keithrozario/Klayers?tab=readme-ov-file
data "aws_ssm_parameter" "klayers_account_prod" {
  count           = local.is-production == true ? 1 : 0
  name            = "klayers-account"
  with_decryption = true
}

# This ID is the elb-account-id for eu-west-2 obtained from https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
data "aws_ssm_parameter" "elb-account-eu-west-2-dev" {
  count           = local.is-development == true ? 1 : 0
  name            = "elb-account-eu-west-2-dev"
  with_decryption = true
}

# Home Office Account ID - used by endpoint service
data "aws_ssm_parameter" "homeoffice_account_prod" {
  count           = local.is-production == true ? 1 : 0
  name            = "homeoffice-account"
  with_decryption = true
}