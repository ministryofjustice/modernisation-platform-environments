module "chatbot_alerts" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  slack_channel_id = "C09C3P43UNP"
  slack_team_id    = "T01067J1X9Q"
  sns_topic_arns   = [aws_sns_topic.emds_alerts.arn]
  tags             = local.tags
  application_name = local.application_name
}
