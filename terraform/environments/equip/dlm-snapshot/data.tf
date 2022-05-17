data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "dlm_lifecycle_role" {
  statement {
    actions = ["sts:AssumeRole", ]
    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}