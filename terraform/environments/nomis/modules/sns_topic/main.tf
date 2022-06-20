data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "sns_topic" {
  name              = "mod-platform-${var.application}-${var.env}"
  display_name      = "SNS Topic for ${var.application}-${var.env}"
  kms_master_key_id = ""
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