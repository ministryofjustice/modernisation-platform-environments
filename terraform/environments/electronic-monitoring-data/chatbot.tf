moved {
  from = module.chatbot_alerts
  to   = module.chatbot_alerts[0]
}

module "chatbot_alerts" {
  count = local.is-production ? 0 : 1

  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=4214f6ab7ecc2224365b110c43269063443b325c"

  # Map Slack channel per environment
  slack_channel_id = {
    test    = "C09C3P43UNP"
    preprod = "C09EVH89M35"
    prod    = "C0CA72GG65B"
    dev     = "C0A51K7L2QG"
  }[local.environment_shorthand]

  slack_team_id  = "T02DYEB3A"
  sns_topic_arns = [aws_sns_topic.emds_alerts.arn]

  user_authorization_required = local.is-development || local.is-test || local.is-preproduction || local.is-production

  guardrail_policies = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    aws_iam_policy.downstream_reconciliation_chatbot_approval.arn,
  ]

  tags             = local.tags
  application_name = local.application_name
}

module "chatbot_operational_incidents" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=4214f6ab7ecc2224365b110c43269063443b325c"

  slack_channel_id = "C0CA72GG65B"
  slack_team_id    = "T02DYEB3A"

  sns_topic_arns = local.is-production ? [
    aws_sns_topic.operational_incident_updates.arn,
    aws_sns_topic.emds_alerts.arn,
    ] : [
    aws_sns_topic.operational_incident_updates.arn,
  ]

  user_authorization_required = local.is-production

  guardrail_policies = local.is-production ? [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    aws_iam_policy.downstream_reconciliation_chatbot_approval.arn,
    ] : [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
  ]

  tags             = local.tags
  application_name = "${local.application_name}-operational-incidents"
}
