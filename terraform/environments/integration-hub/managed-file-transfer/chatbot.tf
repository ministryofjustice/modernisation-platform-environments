module "chatbot_cloudwatch_alarms_high_priority" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  application_name = "${local.application_name}-${local.component_name}-cloudwatch-alarms-high-priority"
  slack_channel_id = local.notification_configuration.high_priority_alerts.slack_channel_id
  slack_team_id    = local.notification_configuration.high_priority_alerts.slack_team_id
  sns_topic_arns   = [module.sns_cloudwatch_alarms_high_priority.topic_arn]
  tags             = local.tags
}

module "chatbot_cloudwatch_alarms_low_priority" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  application_name = "${local.application_name}-${local.component_name}-cloudwatch-alarms-low-priority"
  slack_channel_id = local.notification_configuration.low_priority_alerts.slack_channel_id
  slack_team_id    = local.notification_configuration.low_priority_alerts.slack_team_id
  sns_topic_arns   = [module.sns_cloudwatch_alarms_low_priority.topic_arn]
  tags             = local.tags
}
