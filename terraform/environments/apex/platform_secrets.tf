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

data "aws_ssm_parameter" "app_apex_dbpassword_admin" {
  name            = "APP_APEX_DBPASSWORD_ADMIN"
  with_decryption = true
}

data "aws_ssm_parameter" "ec2_ssh_key" {
  name            = "EC2_SSH_KEY"
  with_decryption = true
}


resource "aws_secretsmanager_secret" "app_apex_dbpassword_tad" {
  name = "APP_APEX_DBPASSWORD_TAD"
}
resource "aws_secretsmanager_secret_version" "app_apex_dbpassword_tad" {
  secret_id     = aws_secretsmanager_secret.app_apex_dbpassword_tad.id
  secret_string = data.aws_ssm_parameter.app_apex_dbpassword_tad.value
}

resource "aws_secretsmanager_secret" "app_apex_dbpassword_admin" {
  name = "APP_APEX_DBPASSWORD_ADMIN"
}
resource "aws_secretsmanager_secret_version" "app_apex_dbpassword_admin" {
  secret_id     = aws_secretsmanager_secret.app_apex_dbpassword_admin.id
  secret_string = data.aws_ssm_parameter.app_apex_dbpassword_admin.value
}

resource "aws_secretsmanager_secret" "ec2_ssh_key" {
  name = "EC2_SSH_KEY"
}
resource "aws_secretsmanager_secret_version" "ec2_ssh_key" {
  secret_id     = aws_secretsmanager_secret.ec2_ssh_key.id
  secret_string = data.aws_ssm_parameter.ec2_ssh_key.value
}