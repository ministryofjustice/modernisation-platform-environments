# Separate output topics prevent formatted notifications re-entering the worker queue.
module "sns_slack" {
  source   = "terraform-aws-modules/sns/aws"
  version  = "7.1.1"
  for_each = local.recipients

  name              = "${local.pattern_name}-${each.key}-slack"
  kms_master_key_id = module.kms_notifications_pipeline.key_arn
  tags              = local.tags
}

module "chatbot_slack" {
  source   = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0
  for_each = local.recipients

  application_name = "${local.pattern_name}-${each.key}"
  slack_channel_id = each.value.slack_channel_id
  slack_team_id    = each.value.slack_team_id
  sns_topic_arns   = [module.sns_slack[each.key].topic_arn]
  # Notifications only: no AWS command permissions for channel users.
  managed_policy_arns = []
  guardrail_policies  = [aws_iam_policy.slack_notifications_only.arn]
  tags                = local.tags
}

resource "aws_iam_policy" "slack_notifications_only" {
  name        = "${local.pattern_name}-slack-notifications-only"
  description = "Disable AWS commands through the file pickup Slack integration"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Deny", Action = "*", Resource = "*" }]
  })
  tags = local.tags
}
