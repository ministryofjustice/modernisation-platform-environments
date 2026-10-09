resource "aws_secretsmanager_secret" "guardduty_slack" {
  #checkov:skip=CKV2_AWS_57: "Secret holds a static slack workspace and channel id"
  name        = "corporate-guardduty-slack"
  description = "Slack workspace and channel IDs for GuardDuty alerts"
  kms_key_id  = module.sherlock_kms_key.key_arn

  tags = local.tags
}

data "aws_secretsmanager_secret_version" "guardduty_slack" {
  count     = local.enable_guardduty_slack_notifications ? 1 : 0
  secret_id = aws_secretsmanager_secret.guardduty_slack.id
}

locals {
  guardduty_slack = local.enable_guardduty_slack_notifications ? jsondecode(data.aws_secretsmanager_secret_version.guardduty_slack[0].secret_string) : null
}

module "guardduty_chatbot" {
  count  = local.enable_guardduty_slack_notifications ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  slack_channel_id = local.enable_guardduty_slack_notifications ? local.guardduty_slack.slack_channel_id : null
  slack_team_id    = local.enable_guardduty_slack_notifications ? local.guardduty_slack.slack_team_id : null
  sns_topic_arns   = [module.data_factory_guardduty_eventbridge.scan_alerts_topic_arn]
  application_name = "${local.application}-${local.component}-guardduty-${local.environment}"
  tags             = local.tags
}