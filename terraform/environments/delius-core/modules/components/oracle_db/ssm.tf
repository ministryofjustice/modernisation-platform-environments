resource "aws_ssm_parameter" "rman_password" {
  name = "/delius-core-${var.env_name}/delius/oracle-db-operation/rman/rman_password"
  type = "SecureString"
  value = "REPLACE"
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

data "aws_ssm_parameter" "rman_password" {
  name = aws_ssm_parameter.rman_password.name
}