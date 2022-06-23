data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "subscriptions" {
  name = "/monitoring/subscription"
}

locals {
  subscriptions_data = sensitive(jsondecode(data.aws_ssm_parameter.subscriptions.value))
}

resource "aws_sns_topic" "sns_topic" {
  name              = "mod-platform-${var.application}-${var.env}"
  display_name      = "SNS Topic for ${var.application}-${var.env}"
  kms_master_key_id = ""
}

resource "aws_sns_topic_subscription" "monitoring_subscriptions" {
  count         = length(local.subscriptions_data.emails)
  topic_arn     = aws_sns_topic.sns_topic.arn
  protocol      = "email"
  endpoint      = local.subscriptions_data.emails[count.index].email
  filter_policy = jsonencode(local.subscriptions_data.emails[count.index].filter)

}

data "aws_iam_policy_document" "policy" {
  statement {
    actions = [
      "sns:ListEndpointsByPlatformApplication",
      "sns:ListPlatformApplications",
      "sns:ListSubscriptions",
      "sns:ListSubscriptionsByTopic",
      "sns:ListTopics",
      "sns:CheckIfPhoneNumberIsOptedOut",
      "sns:GetEndpointAttributes",
      "sns:GetPlatformApplicationAttributes",
      "sns:GetSMSAttributes",
      "sns:GetSubscriptionAttributes",
      "sns:GetTopicAttributes",
      "sns:ListPhoneNumbersOptedOut",
      "sns:ConfirmSubscription",
      "sns:CreatePlatformApplication",
      "sns:CreatePlatformEndpoint",
      "sns:DeleteEndpoint",
      "sns:DeletePlatformApplication",
      "sns:OptInPhoneNumber",
      "sns:Publish",
      "sns:SetEndpointAttributes",
      "sns:SetPlatformApplicationAttributes",
      "sns:SetSMSAttributes",
      "sns:SetSubscriptionAttributes",
      "sns:SetTopicAttributes",
      "sns:Subscribe",
      "sns:Unsubscribe",
    ]

    resources = [
      aws_sns_topic.sns_topic.arn,
    ]
  }
}

resource "aws_iam_policy" "policy" {
  name   = "sns-topic-${var.application}-${var.env}"
  policy = data.aws_iam_policy_document.policy.json
}