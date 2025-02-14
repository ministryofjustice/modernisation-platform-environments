#### This file can be used to store data specific to the member account ####
data "aws_iam_policy_document" "aws_transfer_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "call_centre_access_policy" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    effect    = "Allow"
    resources = [aws_s3_bucket.call_centre.arn]
    sid       = "AllowListingOfBucket"
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObjectVersion",
      "s3:GetObjectACL",
      "s3:PutObjectACL"
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.call_centre.arn}/*"]
    sid       = "AllowAccessToBucketObjects"
  }
  statement {
    actions   = ["kms:*"]
    effect    = "Allow"
    resources = [aws_kms_key.call_centre.arn]
    sid       = "AllowAccessToKMSKey"
  }
  statement {
    actions = [
      "secretsmanager:BatchGet*",
      "secretsmanager:Describe*",
      "secretsmanager:Get*",
      "secretsmanager:List*"
    ]
    effect    = "Allow"
    resources = [aws_secretsmanager_secret.call_centre.arn]
    sid       = "AllowAccessToSecrets"
  }
}

data "aws_iam_policy_document" "call_centre_bucket_policy" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    resources = [aws_s3_bucket.call_centre.arn]
    sid       = "AllowListingOfBucket"
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObjectVersion",
      "s3:GetObjectACL",
      "s3:PutObjectACL"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    resources = ["${aws_s3_bucket.call_centre.arn}/*"]
    sid       = "AllowAccessToBucketObjects"
  }
}

data "aws_iam_policy_document" "call_centre_kms_policy" {
  statement {
    sid    = "KeyAdministration"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = [aws_kms_key.call_centre.arn]
  }
  statement {
    sid    = "AllowAWSServiceAccess"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com", "s3.amazonaws.com"]
    }
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:ReEncrypt*"
    ]
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "kms:CallerAccount"
    }
    condition {
      test     = "StringLike"
      values   = ["transfer.amazonaws.com", "s3.amazonaws.com"]
      variable = "kms:ViaService"
    }
    resources = [aws_kms_key.call_centre.arn]
  }
}