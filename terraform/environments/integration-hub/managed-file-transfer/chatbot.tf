module "chatbot_clean_file_download_notifications" {
  count = local.notification_configuration.slack_channel_id != null && local.notification_configuration.slack_team_id != null ? 1 : 0

  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  slack_channel_id = local.notification_configuration.slack_channel_id
  slack_team_id    = local.notification_configuration.slack_team_id
  sns_topic_arns   = [aws_sns_topic.clean_file_download_notifications.arn]
  tags             = local.tags
  application_name = local.application_name
}
