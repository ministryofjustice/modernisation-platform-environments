resource "aws_ssm_parameter" "plain" {
  for_each = toset([for item in var.params_plain : item])
  name     = "/${var.environment_name}/${var.application_name}/${each.value}"
  type     = "String"
  value    = "change_me"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "secure" {
  for_each = toset([for item in var.params_secure : item])
  name     = "/${var.environment_name}/${var.application_name}/${each.value}"
  type     = "SecureString"
  value    = "change_me"
  lifecycle {
    ignore_changes = [value]
  }
}
