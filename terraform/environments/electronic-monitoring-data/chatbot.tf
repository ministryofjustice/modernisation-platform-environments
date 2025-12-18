module "chatbot_alerts" {
  count  = local.is-development ? 0 : 1
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  # Map Slack channel per environment
  slack_channel_id = {
    test    = "C09C3P43UNP"
    preprod = "C09EVH89M35"
    prod    = "C069RF589V4"
    dev     = "C0A51K7L2QG"
  }[local.environment_shorthand]

  slack_team_id    = "T02DYEB3A"
  sns_topic_arns   = [aws_sns_topic.emds_alerts.arn]
  tags             = local.tags
  application_name = local.application_name
}