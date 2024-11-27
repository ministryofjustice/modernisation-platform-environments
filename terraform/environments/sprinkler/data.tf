#### This file can be used to store data specific to the member account ####

data "aws_caller_identity" "core_vpc" {
  provider = aws.core-vpc
}

data "aws_caller_identity" "core_network_services" {
  provider = aws.core-network-services
}

data "aws_caller_identity" "us_east_1" {
  provider = aws.us-east-1
}

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