resource "random_password" "apps_ro_password" {
  length  = 10
  special = false
}

resource "aws_ssm_parameter" "secret" {
  for_each    = local.dblink_secrets
  name        = each.value.name
  description = each.value.description
  type        = "SecureString"
  value       = each.value.secret_value

  tags = merge(
    local.tags,
    { "Name" = each.value.name }
  )
}
