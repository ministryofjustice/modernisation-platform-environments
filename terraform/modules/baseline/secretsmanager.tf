# This file is pretty much the same as ssm.tf, to make it easy to switch
# between SSM parameters and SecretManager Secrets
# Use Secrets if you need to share a parameter across accounts.

locals {
  secretsmanager_secrets_list = flatten([
    for sm_key, sm_value in var.secretsmanager_secrets : [
      for secret_name, secret_value in sm_value.secrets : {
        key = "${sm_value.prefix}${sm_key}${sm_value.postfix}${secret_name}"
        value = merge(
          {
            policy_key              = sm_key,
            policy                  = sm_value.policy,
            recovery_window_in_days = sm_value.recovery_window_in_days
          },
          secret_value,
          secret_value.kms_key_id == null ? { kms_key_id = sm_value.kms_key_id } : {}
        )
      }
    ]
  ])

  secretsmanager_random_passwords = {
    for item in local.secretsmanager_secrets_list :
    item.key => item.value.random if item.value.random != null
  }

  secretsmanager_secrets_value = {
    for item in local.secretsmanager_secrets_list :
    item.key => item.value if item.value.value != null
  }

  secretsmanager_secrets_random = {
    for item in local.secretsmanager_secrets_list :
    item.key => merge(item.value, {
      value = random_password.secrets[item.key].result
    }) if item.value.value == null && item.value.random != null
  }

  secretsmanager_secrets_file = {
    for item in local.secretsmanager_secrets_list :
    item.key => merge(item.value, {
      value = file(item.value.file)
    }) if item.value.value == null && item.value.random == null && item.value.file != null
  }

  secretsmanager_secrets_default = {
    for item in local.secretsmanager_secrets_list :
    item.key => merge(item.value, {
      value = "placeholder, overwrite me outside of terraform"
    }) if item.value.value == null && item.value.random == null && item.value.file == null
  }

}

resource "random_password" "secrets" {
  for_each = local.secretsmanager_random_passwords

  length  = each.value.length
  special = each.value.special
}

data "aws_iam_policy_document" "secretsmanager_secret_policy" {
  for_each = {
    for key, value in var.secretsmanager_secrets : key => value if value.policy != null
  }

  dynamic "statement" {
    for_each = each.value.policy
    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
      dynamic "principals" {
        for_each = statement.value.principals != null ? [statement.value.principals] : []
        content {
          type        = principals.value.type
          identifiers = [for identifier in principals.value.identifiers : try(var.environment.account_root_arns[identifier], identifier)]
        }
      }
      dynamic "condition" {
        for_each = statement.value.conditions
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_secretsmanager_secret" "this" {
  #checkov:skip=CKV2_AWS_57:Ensure Secrets Manager secrets should have automatic rotation enabled; needs to be manual as these are intended to store things like DB passwords

  for_each = merge(
    local.secretsmanager_secrets_value,
    local.secretsmanager_secrets_random,
    local.secretsmanager_secrets_file,
    local.secretsmanager_secrets_default
  )

  name                    = each.key
  description             = each.value.description
  kms_key_id              = each.value.kms_key_id != null ? try(var.environment.kms_keys[each.value.kms_key_id].arn, each.value.kms_key_id) : null
  policy                  = each.value.policy != null ? data.aws_iam_policy_document.secretsmanager_secret_policy[each.value.policy_key].json : null
  recovery_window_in_days = each.value.recovery_window_in_days

  tags = merge(local.tags, {
    Name = each.key
  })
}

resource "aws_secretsmanager_secret_version" "fixed" {
  for_each = merge(
    local.secretsmanager_secrets_value,
    local.secretsmanager_secrets_random,
    local.secretsmanager_secrets_file
  )

  secret_id     = aws_secretsmanager_secret.this[each.key]
  secret_string = each.value.value
}

resource "aws_secretsmanager_secret_version" "placeholder" {
  for_each = local.secretsmanager_secrets_default

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value.value

  lifecycle {
    ignore_changes = [secret_string]
  }
}
