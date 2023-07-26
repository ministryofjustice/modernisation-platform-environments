###################################################
# DPR Notifications
###################################################

# Notification SNS
module "notifications_sns" {
  source         = "./modules/notifications/sns"
  sns_topic_name = "${local.project}-notification-topic-${local.environment}"

  tags = merge(
    local.all_tags,
    {
      Name = "${local.project}-notifications-sns-${local.environment}"
      Jira = "DPR-569",
      Dept = "Digital-Prison-Reporting"
    }
  )
}

# Slack alerts
module "slack_alerts" {
  count = local.enable_slack_alerts ? 1 : 0

  source     = "./modules/notifications/email"

  sns_topic_arn = module.notifications_sns.sns_topic_arn
  email_url     = local.enable_slack_alerts ? data.aws_secretsmanager_secret_version.slack_integration[0].secret_string : null

  tags = merge(
    local.all_tags,
    {
      Name = "${local.project}-slack-alerts-${local.environment}"
      Jira = "DPR-569",
      Dept = "Digital-Prison-Reporting"
    }
  )

  depends_on = [module.notifications_sns, module.slack_alerts_url.secret_id]
}

# PagerDuty notifications
module "pagerduty_notifications" {
  count      = local.enable_pagerduty_alerts ? 1 : 0

  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
  sns_topics                = ["${local.project}-notification-topic-${local.environment}"]
  pagerduty_integration_key = data.aws_secretsmanager_secret_version.pagerduty_integration[0].secret_string

  depends_on = [module.notifications_sns, module.pagerduty_integration_key.secret_id]
}

# Glue status change rule
module "glue_status_change_rule" {
  source        = "./modules/notifications/eventbridge"
  sns_topic_arn = module.notifications_sns.sns_topic_arn

  rule_name         = "${local.project}-glue-jobs-status-change-rule-${local.environment}"
  event_target_name = "${local.project}-glue-rule-target-${local.environment}"

  event_pattern = <<PATTERN
{
  "source": ["aws.glue"],
  "detail-type": ["Glue Job State Change"],
  "detail": {
    "state": ["STOPPED", "FAILED", "TIMEOUT"]
  }
}
PATTERN

  tags = merge(
    local.all_tags,
    {
      Name = "${local.project}-glue-status-change-rule-${local.environment}",
      Jira = "DPR-569",
      Dept = "Digital-Prison-Reporting"
    }
  )

  depends_on = [module.notifications_sns]
}