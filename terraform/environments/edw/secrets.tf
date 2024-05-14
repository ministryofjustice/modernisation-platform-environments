#### This file can be used to store secrets specific to the member account ####
resource "aws_secretsmanager_secret" "edw_db_secret" {
  name        = "${local.application_name}/app/db-master-password"
  description = "EDW DB Password"
}

resource "aws_secretsmanager_secret" "edw_ec2_root_secret" {
  name        = "${local.application_name}/app/db-EC2-root-password"
  description = "EDW DB EC2 Root Password"
  }

resource "aws_secretsmanager_rotation" "edw_db_root_rotate" {
  secret_id                  = aws_secretsmanager_secret.edw_db_ec2_root_secret.id
#  rotation_lambda_arn        = data.aws_ssm_parameter.SecretsRotation.arn
  rotate_immediately = true
  rotation_rules {
    automatically_after_days = 28
  }
}
