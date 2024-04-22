resource "aws_ssm_parameter" "this" {
  for_each = toset([for item in var.params_list : item])
  name     = "/${var.environment_name}/${var.application_name}/${each.value}"
  type     = "SecureString"
  value    = "change_me"
  lifecycle {
    ignore_changes = [value]
  }
}
