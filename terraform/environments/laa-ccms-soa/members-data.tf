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