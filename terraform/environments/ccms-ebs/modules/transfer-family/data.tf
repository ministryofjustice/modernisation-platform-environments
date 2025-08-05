#--Transfer Family IAM Docs
data "aws_iam_policy_document" "transfer_assume_role" {
  version = "2012-10-17"
  statement {
    sid    = "AllowTransferAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:SetContext"
    ]
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "transfer" {
  statement {
    sid    = "AllowS3Grants"
    effect = "Allow"
    actions = [
      "s3:GetDataAccess",
      "s3:ListCallerAccessGrants",
    "s3:ListAccessGrantsInstances"]
    resources = ["*"]
  }
}

#--S3 Family IAM Docs
data "aws_iam_policy_document" "s3_assume_role" {
  version = "2012-10-17"
  statement {
    sid    = "AccessGrantsTrustPolicy"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:SetSourceIdentity"
    ]
    principals {
      type        = "Service"
      identifiers = ["access-grants.s3.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:s3:eu-west-2:${var.aws_account_id}:access-grants/default"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = ["${var.aws_account_id}"]
    }
  }
  statement {
    sid     = "AccessGrantsTrustPolicyWithIDCContext"
    effect  = "Allow"
    actions = ["sts:SetContext"]
    principals {
      type        = "Service"
      identifiers = ["access-grants.s3.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:s3:eu-west-2:${var.aws_account_id}:access-grants/default"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = ["${var.aws_account_id}"]
    }
    condition {
      test     = "ForAllValues:ArnEquals"
      variable = "sts:RequestContextProviders"
      values   = ["arn:aws:iam::aws:contextProvider/IdentityCenter"]
    }
  }
}

data "aws_iam_policy_document" "s3" {
  statement {
    sid    = "ObjectLevelReadPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectAcl",
      "s3:GetObjectVersionAcl",
    "s3:ListMultipartUploadParts"]
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = ["${var.aws_account_id}"]
    }
    condition {
      test     = "ArnEquals"
      variable = "s3:AccessGrantsInstanceArn"
      values   = ["arn:aws:s3:eu-west-2:${var.aws_account_id}:access-grants/default"]
    }
  }
  statement {
    sid    = "ObjectLevelWritePermissions"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectVersionAcl",
    "s3:AbortMultipartUpload", ]
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = ["${var.aws_account_id}"]
    }
    condition {
      test     = "ArnEquals"
      variable = "s3:AccessGrantsInstanceArn"
      values   = ["arn:aws:s3:eu-west-2:${var.aws_account_id}:access-grants/default"]
    }
  }
  statement {
    sid       = "BucketLevelReadPermissions"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.bucket_name}"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = ["${var.aws_account_id}"]
    }
    condition {
      test     = "ArnEquals"
      variable = "s3:AccessGrantsInstanceArn"
      values   = ["arn:aws:s3:eu-west-2:${var.aws_account_id}:access-grants/default"]
    }
  }
}