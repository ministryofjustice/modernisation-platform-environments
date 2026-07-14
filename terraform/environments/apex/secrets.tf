#### This file can be used to store secrets specific to the member account ####
data "aws_ssm_parameter" "app_apex_dbpassword_tad" {
  name            = "APP_APEX_DBPASSWORD_TAD"
  with_decryption = true
}
data "aws_ssm_parameter" "ec2_ssh_key" {
  name            = "EC2_SSH_KEY"
  with_decryption = true
}

data "aws_ssm_parameter" "app_apex_dbpassword_admin" {
  count           = local.environment == "test" ? 1 : 0
  name            = "APP_APEX_DBPASSWORD_ADMIN"
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

resource "aws_secretsmanager_secret" "app_apex_dbpassword_admin" {
  count = local.environment == "test" ? 1 : 0
  name  = "APP_APEX_DBPASSWORD_ADMIN"
}
resource "aws_secretsmanager_secret_version" "app_apex_dbpassword_admin" {
  count         = local.environment == "test" ? 1 : 0
  secret_id     = aws_secretsmanager_secret.app_apex_dbpassword_admin[0].id
  secret_string = data.aws_ssm_parameter.app_apex_dbpassword_admin[0].value
}

