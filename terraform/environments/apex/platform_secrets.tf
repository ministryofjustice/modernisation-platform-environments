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

data "aws_ssm_parameter" "app_apex_dbpassword_tad" {
  name            = "APP_APEX_DBPASSWORD_TAD"
  with_decryption = true
}
data "aws_ssm_parameter" "ec2_ssh_key" {
  name            = "EC2_SSH_KEY"
  with_decryption = true
}


resource "aws_secretsmanager_secret" "app_apex_dbpassword_tad" {
  count = local.environment == "development" ? 1 : 0
  name  = "APP_APEX_DBPASSWORD_TAD"
}
resource "aws_secretsmanager_secret_version" "app_apex_dbpassword_tad" {
  count         = local.environment == "development" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.app_apex_dbpassword_tad[0].id
  secret_string = data.aws_ssm_parameter.app_apex_dbpassword_tad.value
}
resource "aws_secretsmanager_secret" "ec2_ssh_key" {
  count = local.environment == "development" ? 1 : 0
  name  = "EC2_SSH_KEY"
}
resource "aws_secretsmanager_secret_version" "ec2_ssh_key" {
  count         = local.environment == "development" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.ec2_ssh_key[0].id
  secret_string = data.aws_ssm_parameter.ec2_ssh_key.value
}