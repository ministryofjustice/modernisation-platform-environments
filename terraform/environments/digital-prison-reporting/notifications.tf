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
#module "slack_alerts" {
#  count = local.enable_slack_alerts ? 1 : 0
#
#  depends_on = [module.notifications_sns]
#  source     = "./modules/notifications/slack"
#
#  sns_topic_arn   = module.notifications_sns.sns_topic_arn
#  slack_email_url = local.enable_slack_alerts ? data.aws_secretsmanager_secret_version.slack_integration[0].secret_string : null
#
#  tags = merge(
#    local.all_tags,
#    {
#      Name = "${local.project}-slack-alerts-${local.environment}"
#      Jira = "DPR-569",
#      Dept = "Digital-Prison-Reporting"
#    }
#  )
#}

# PagerDuty notifications
#module "pagerduty_notifications" {
#  count      = local.enable_pagerduty_alerts ? 1 : 0
#  depends_on = [module.notifications_sns]
#
#  source                    = "github.com/ministryofjustice/modernisation-platform-terraform-pagerduty-integration?ref=v2.0.0"
#  sns_topics                = ["${local.project}-notification-topic-${local.environment}"]
#  pagerduty_integration_key = data.aws_secretsmanager_secret_version.pagerduty_integration[0].secret_string
#}

# Glue status change rule
#module "glue_status_change" {
#  depends_on = [module.notifications_sns]
#
#  source                = "./modules/notifications/glue"
#  sns_topic_arn         = module.notifications_sns.sns_topic_arn
#  glue_rule_name        = "${local.project}-glue-jobs-status-change-rule-${local.environment}"
#  glue_rule_target_name = "${local.project}-glue-rule-target-${local.environment}"
#
#  tags = merge(
#    local.all_tags,
#    {
#      Name = "${local.project}-glue-status-change-rule-${local.environment}",
#      Jira = "DPR-569",
#      Dept = "Digital-Prison-Reporting"
#    }
#  )
#}