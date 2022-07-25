data "aws_backup_vault" "backup-vault" {
  name        = "everything"
}

resource "aws_backup_plan" "backup-plan" {
  name = "${var.application_name}-${var.environment}_plan"
  dynamic "rule" {
    for_each = var.rules
    content {
      rule_name                = lookup(rule.value, "name", null)
      target_vault_name        = data.aws_backup_vault.backup-vault.name
      schedule                 = lookup(rule.value, "schedule", null)
      start_window             = lookup(rule.value, "start_window", null)
      completion_window        = lookup(rule.value, "completion_window", null)
      enable_continuous_backup = lookup(rule.value, "enable_continuous_backup", null)
      recovery_point_tags = {
        Frequency  = lookup(rule.value, "name", null)
        Created_By = "aws-backup"
      }
      lifecycle {
        delete_after = lookup(rule.value, "delete_after", null)
      }
    }
  }
}

resource "aws_backup_selection" "backup-selection" {
  iam_role_arn = aws_iam_role.aws-backup-service-role.arn
  name         = "backup_resources"
  plan_id      = aws_backup_plan.backup-plan.id
  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.key
    value = var.value
  }
}