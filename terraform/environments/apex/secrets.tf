#### This file can be used to store secrets specific to the member account ####
data "aws_secretsmanager_secret" "app_apex_dbpassword_tad" {
  name = "APP_APEX_DBPASSWORD_TAD"
}

data "aws_secretsmanager_secret" "ec2_ssh_key" {
  name = "EC2_SSH_KEY"
}

data "aws_secretsmanager_secret" "app_apex_dbpassword_admin" {
  count = contains(["test", "preproduction"], local.environment) ? 1 : 0
  name  = "APP_APEX_DBPASSWORD_ADMIN"
}

removed {
  from = aws_secretsmanager_secret.app_apex_dbpassword_tad

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_secretsmanager_secret.ec2_ssh_key

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_secretsmanager_secret.app_apex_dbpassword_admin

  lifecycle {
    destroy = false
  }
}

