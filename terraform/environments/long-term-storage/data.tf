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

data "aws_iam_policy_document" "aws_transfer_user_policy" {
  statement {
    actions   = ["s3:ListObjects"]
    effect    = "Allow"
    resources = [aws_s3_bucket.call_center.arn]
  }
}