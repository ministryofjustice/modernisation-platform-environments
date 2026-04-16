locals {
  cwagent_log_groups = [
    "cwagent-var-log-messages",
    "cwagent-var-log-secure",
    "cwagent-windows-system",
    "cwagent-windows-application",
    "cwagent-windows-security",
    "cwagent-windows-security",
  ]
}

resource "aws_cloudwatch_log_group" "cwagent" {
  for_each = toset(local.cwagent_log_groups)

  name              = each.key
  retention_in_days = local.is-production ? 400 : 30 # 13 month retention on prod as per MOJ guidance
  kms_key_id        = local.account_config.kms_keys.general_shared

  tags = merge(local.tags, {
    Name = each.key
  })
}
