locals {
  params_plain = (
    can(tomap(var.params_plain))
    ? tomap(var.params_plain)
    : { for p in var.params_plain : p => "change_me" }
  )
}

resource "aws_ssm_parameter" "plain" {
  for_each = local.params_plain
  name     = "/${var.environment_name}/${var.application_name}/${each.key}"
  type     = "String"
  value    = each.value
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
