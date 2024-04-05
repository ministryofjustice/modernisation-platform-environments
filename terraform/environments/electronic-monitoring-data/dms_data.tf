data "aws_s3_bucket" "existing_dms_bucket" {
  bucket = "dms-em-rds-output"
}

data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.eu-west-2.amazonaws.com"]
      type        = "Service"
    }
  }
}
