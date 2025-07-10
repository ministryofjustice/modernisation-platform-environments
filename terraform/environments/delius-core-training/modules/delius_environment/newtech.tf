resource "aws_ssm_parameter" "pdfcreation_secret" {
  name  = "/${var.env_name}/delius/newtech/web/params_secret_key"
  type  = "SecureString"
  value = "DEFAULT"
  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "pdfcreation_secret" {
  name = aws_ssm_parameter.pdfcreation_secret.name
}
