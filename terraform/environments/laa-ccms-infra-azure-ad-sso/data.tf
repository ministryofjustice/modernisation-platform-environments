#### This file can be used to store data specific to the member account ####
data "aws_ami" "oracle_ebs_vision_db" {
  most_recent = true
  owners      = [local.application_data.accounts[local.environment].ami_owner]

  filter {
    name   = "name"
    values = [local.application_data.accounts[local.environment].imported_ebsdb_image_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
## S3 NOTIFICATIONS
data "aws_iam_policy_document" "s3_topic_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:s3-event-notification-topic"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        module.s3-bucket-logging.bucket.arn
      ]
    }
  }
}

## IAM
data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "SnsTopicId"
  statement {
    sid = "statement1"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect = "Allow"
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive"
    ]
    resources = [aws_sns_topic.cw_alerts.arn]
  }
}
