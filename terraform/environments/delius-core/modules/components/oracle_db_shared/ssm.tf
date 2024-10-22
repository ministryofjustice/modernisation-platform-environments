# checkov:skip=all
resource "aws_ssm_parameter" "rman_password" {
  name  = "/${var.account_info.application_name}-${var.env_name}/delius/oracle-${var.db_suffix}-operation/rman/rman_password"
  type  = "SecureString"
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
