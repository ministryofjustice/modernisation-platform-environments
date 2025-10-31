data "aws_iam_policy_document" "dms_assume_role" {
  count = local.is-production || local.is-development ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.eu-west-2.amazonaws.com"]
      type        = "Service"
    }
  }
}
