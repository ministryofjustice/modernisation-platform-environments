data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      module.log_bucket.bucket.arn
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.cloudtrail_arn]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${module.log_bucket.bucket.arn}/AWSLogs/${local.account_id}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.cloudtrail_arn]
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "cloudtrail_cloudwatch_logs" {
  statement {
    sid    = "WriteCloudTrailLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    ]
  }
}

resource "aws_iam_role" "cloudtrail_logs" {
  name               = "${local.cloudtrail_name}-cloudtrail-logs"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role.json
  tags = var.tags
}

resource "aws_iam_role_policy" "cloudtrail_logs" {
  name   = "${local.cloudtrail_name}-cloudtrail-logs"
  role   = aws_iam_role.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_logs.json
}

data "aws_iam_policy_document" "cloudtrail_sns_publish" {
  statement {
    sid    = "AllowCloudTrailToPublishToSNS"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["sns:Publish"]

    resources = [aws_sns_topic.cloudtrail.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudtrail.sherlock.arn]
    }
  }
}

resource "aws_sns_topic_policy" "cloudtrail" {
  arn    = aws_sns_topic.cloudtrail.arn
  policy = data.aws_iam_policy_document.cloudtrail_sns_publish.json
}