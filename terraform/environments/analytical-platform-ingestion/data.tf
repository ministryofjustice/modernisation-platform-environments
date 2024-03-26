#### This file can be used to store data specific to the member account ####
data "aws_availability_zones" "available" {}

data "aws_iam_policy_document" "s3_download_kms_policy" {
  statement {
    sid       = "AllowS3Download"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
}