resource "aws_kms_key" "oracle_ec2" {
  enable_key_rotation = true

  tags = merge(local.tags,
    { Name = "oracle_ec2" }
  )
}

resource "aws_kms_alias" "oracle_ec2_alias" {
  name          = "alias/ec2_oracle_key"
  target_key_id = aws_kms_key.oracle_ec2.arn
}

resource "aws_kms_key" "cloudwatch_sns_alerts_key" {
  description             = "KMS Key for CloudWatch SNS Alerts Encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(local.tags,
    { Name = lower(format("%s-%s-cloudwatch-sns-alerts-kms-key", local.application_name, local.environment)) }
  )
}

resource "aws_kms_alias" "cloudwatch_sns_alerts_key_alias" {
  name          = "alias/cloudwatch-sns-alerts-key"
  target_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
}

data "aws_iam_policy_document" "cloudwatch_sns_encryption" {
  version = "2012-10-17"
  statement {
    sid    = "AllowCloudWatchSNSUseOfTheKey"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "cloudwatch.amazonaws.com",
        "events.amazonaws.com",
        "s3.amazonaws.com"
      ]
    }
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowAccountAdmins"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key_policy" "sns_alerts_key_policy" {
  key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
  policy = data.aws_iam_policy_document.cloudwatch_sns_encryption.json
}