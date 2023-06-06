locals {

  ssm_parameters_list = flatten([
    for sp_key, sp_value in var.ssm_parameters : [
      for param_name, param_value in sp_value.names : {
        key   = "${sp_value.prefix}${sp_key}${sp_value.postfix}${param_name}"
        value = param_value
      }
    ]
  ])

  random_passwords = {
    for item in local.ssm_parameters_list :
    item.key => item.value.random if item.value.random != null
  }

  ssm_parameters_random = {
    for item in local.ssm_parameters_list :
    item.key => merge(item.value, {
      value = random_password.this[item.key].result
    }) if item.value.random != null
  }

  ssm_parameters_file = {
    for item in local.ssm_parameters_list :
    item.key => merge(item.value, {
      value = file(item.value.file)
    }) if item.value.file != null
  }

  ssm_parameters_value = {
    for item in local.ssm_parameters_list :
    item.key => item.value if item.value.file == null && item.value.random == null
  }

  ssm_parameters = merge(
    local.ssm_parameters_random,
    local.ssm_parameters_file,
    local.ssm_parameters_value
  )
}

resource "random_password" "this" {
  for_each = local.random_passwords

  length  = each.value.length
  special = each.value.special
}

resource "aws_ssm_parameter" "this" {
  for_each = local.ssm_parameters

  name        = each.key
  description = each.value.description
  type        = each.value.type
  key_id      = each.value.key_id != null ? try(var.environment.kms_keys[each.value.key_id].arn, each.value.key_id) : null
  value       = each.value.value

  tags = merge(local.tags, {
    Name = each.key
  })

  lifecycle {
    ignore_changes = [value]
  }
}
