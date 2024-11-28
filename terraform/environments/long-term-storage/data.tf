#### This file can be used to store data specific to the member account ####
data "aws_iam_policy_document" "aws_transfer_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "stringEquals"
      values = [data.aws_caller_identity.current.account_id]
      variable = "aws:SourceAccount"
    }

    condition {
      test     = "ArnLike"
      values = ["arn:aws:transfer:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:user/*"]
      variable = "aws:SourceArn"
    }
  }
}

data "aws_iam_policy_document" "aws_transfer_user_policy" {
  statement {
    actions   = ["s3:ListObjects"]
    effect    = "Allow"
    resources = [aws_s3_bucket.call_center.arn]
  }
}