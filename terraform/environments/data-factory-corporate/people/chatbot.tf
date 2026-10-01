variable "enable_guardduty_slack_notifications" {
  description = "Enable GuardDuty Slack notifications after the guardduty-slack secret has a value."
  type        = bool
  default     = false
}

resource "aws_secretsmanager_secret" "guardduty_slack" {
  name        = "guardduty-slack"
  description = "Slack workspace and channel IDs for GuardDuty alerts"
  kms_key_id  = module.sherlock_kms_key.key_arn

  tags = local.tags
}

data "aws_secretsmanager_secret_version" "guardduty_slack" {
  count     = var.enable_guardduty_slack_notifications ? 1 : 0
  secret_id = aws_secretsmanager_secret.guardduty_slack.id
}

locals {
  guardduty_slack = var.enable_guardduty_slack_notifications ? jsondecode(data.aws_secretsmanager_secret_version.guardduty_slack[0].secret_string) : null
}

module "guardduty_chatbot" {
  count  = var.enable_guardduty_slack_notifications ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  slack_channel_id = local.guardduty_slack.slack_channel_id
  slack_team_id    = local.guardduty_slack.slack_team_id
  sns_topic_arns   = [module.data_factory_guardduty_eventbridge.scan_alerts_topic_arn]
  application_name = "${local.application}-${local.component}-guardduty-${local.environment}"
  tags             = local.tags
}