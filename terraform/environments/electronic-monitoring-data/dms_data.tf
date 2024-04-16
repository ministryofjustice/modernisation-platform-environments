data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.eu-west-2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["glue.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "dms_target_ep_s3_bucket" {
  statement {
    sid = "EnforceTLSv12orHigher"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.dms_target_ep_s3_bucket.arn,
      "${aws_s3_bucket.dms_target_ep_s3_bucket.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

# data "aws_iam_policy_document" "dms_policies" {
#   statement {
#     effect    = "Allow"
#     actions   = ["dms:CreateReplicationSubnetGroup"]
#     resources = ["*"]
#   }
# }
