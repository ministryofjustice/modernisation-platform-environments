module "chatbot_alerts" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot"

  slack_channel_id = "C09C3P43UNP"
  slack_team_id    = "T01067J1X9Q"
  sns_topic_arns   = [aws_sns_topic.emds_alerts.arn]
  tags             = local.tags
  application_name = local.application_name
}
