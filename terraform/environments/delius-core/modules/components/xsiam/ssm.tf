resource "aws_ssm_parameter" "xsiam_endpoint" {
  name        = "/${var.env_name}/${var.app_name}/xsiam_endpoint"
  description = "XSIAM endpoint for ${var.env_name} environment"
  type        = "SecureString"
  value       = "change_me"
  lifecycle {
    ignore_changes = [value]
  }
}