data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.eu-west-2.amazonaws.com"]
      type        = "Service"
    }
  }
}
