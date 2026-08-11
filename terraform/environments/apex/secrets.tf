#### This file can be used to store secrets specific to the member account ####
resource "aws_secretsmanager_secret" "app_apex_dbpassword_tad" {
  name = "APP_APEX_DBPASSWORD_TAD"
}

resource "aws_secretsmanager_secret" "ec2_ssh_key" {
  name = "EC2_SSH_KEY"
}

resource "aws_secretsmanager_secret" "app_apex_dbpassword_admin" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0
  name  = "APP_APEX_DBPASSWORD_ADMIN"
}

