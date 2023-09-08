locals {

  # everything vault is created by mod platform
  backup_vaults = {
    for key, value in var.backups : key => value if key != "everything"
  }

  backup_plans_list = flatten([
    for vault_key, vault_value in var.backups : [
      for plan_key, plan_value in vault_value.plans : [{
        key = "${vault_key}-${plan_key}"
        value = merge(plan_value, {
          target_vault_name = vault_key
        })
      }]
    ]
  ])

  backup_plans = {
    for item in local.backup_plans_list : item.key => item.value
  }

}

# created elsewhere (modernisation-platform-terraform-baselines)
data "aws_backup_vault" "everything" {
  name = "everything"
}

# created elsewhere (modernisation-platform-terraform-baselines)
data "aws_iam_role" "backup" {
  name = "AWSBackup"
}

resource "aws_backup_vault" "this" {
  for_each = local.backup_vaults

  name        = each.key
  kms_key_arn = try(var.environment.kms_keys[each.value.kms_key_id].arn, each.value.kms_key_id)

  tags = merge(local.tags, each.value.tags, {
    Name = each.key
  })
}

resource "aws_backup_plan" "this" {
  for_each = local.backup_plans

  name = each.key

  rule {
    rule_name                = each.key
    target_vault_name        = each.value.target_vault_name
    schedule                 = each.value.rule.schedule
    enable_continuous_backup = each.value.rule.enable_continuous_backup
    start_window             = each.value.rule.start_window
    completion_window        = each.value.rule.completion_window

    lifecycle {
      cold_storage_after = each.value.rule.cold_storage_after
      delete_after       = each.value.rule.delete_after
    }
  }

  dynamic "advanced_backup_setting" {
    for_each = each.value.advanced_backup_setting != null ? [each.value.advanced_backup_setting] : []
    content {
      backup_options = advanced_backup_setting.value.backup_options
      resource_type  = advanced_backup_setting.value.resource_type
    }
  }

  tags = merge(local.tags, each.value.tags, {
    Name = each.key
  })
}

resource "aws_backup_selection" "this" {
  for_each = local.backup_plans

  name          = each.key
  iam_role_arn  = data.aws_iam_role.backup.arn
  plan_id       = aws_backup_plan.this[each.key].id
  resources     = each.value.selection.resources
  not_resources = each.value.selection.not_resources

  dynamic "selection_tag" {
    for_each = each.value.selection.selection_tags
    content {
      type  = selection_tag.value.type
      key   = selection_tag.value.key
      value = selection_tag.value.value
    }
  }
}
