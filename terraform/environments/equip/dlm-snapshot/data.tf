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

data "aws_iam_policy_document" "dlm_lifecycle_policy" {
  statement {
    actions   = ["ec2:CreateTags", ]
    resources = ["arn:aws:ec2::${data.aws_caller_identity.current.account_id}:snapshot/*"]
  }

  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:DeleteSnapshot",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots"
    ]
    resources = ["arn:aws:ec2::${data.aws_caller_identity.current.account_id}"]
  }
}