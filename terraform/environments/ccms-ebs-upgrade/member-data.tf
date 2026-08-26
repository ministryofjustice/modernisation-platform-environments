#### This file can be used to store data specific to the member account ####


## SECRETS
data "aws_secretsmanager_secret" "support_email_account" {
  name = "support_email_account"
  depends_on = [
    aws_secretsmanager_secret.support_email_account
  ]
}

data "aws_secretsmanager_secret_version" "support_email_account" {
  secret_id = data.aws_secretsmanager_secret.support_email_account.id
  depends_on = [
    aws_secretsmanager_secret_version.support_email_account
  ]
}

## SECURITY GROUPS
data "aws_security_groups" "all_security_groups" {
  filter {
    name   = "tag:Name"
    values = ["*ccms*"]
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
        module.s3-bucket.bucket.arn,
        module.s3-bucket-logging.bucket.arn,
        module.s3-bucket-dbbackup.bucket.arn
      ]
    }
  }
}


