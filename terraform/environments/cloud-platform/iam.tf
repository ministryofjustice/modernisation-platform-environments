# Role to allow cloud-platform-live to make eks changes
# Enables the container-platform-environments repo to manage eks access entries across cluster accounts
data "aws_iam_policy_document" "trust" {
  statement {
    sid     = "AllowSourceAccountAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["cloud-platform-live"]}:root"]
    }
  }
}

resource "aws_iam_role" "eks_access" {
  name               = "ContainerPlatformEKSAccess"
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

data "aws_iam_policy_document" "eks_access" {
  statement {
    sid    = "DiscoverPermissionSetRoles"
    effect = "Allow"
    actions = [
      "iam:ListRoles"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CreateAndListAccessEntriesOnApprovedClusters"
    effect = "Allow"
    actions = [
      "eks:CreateAccessEntry",
      "eks:ListAccessEntries",
      "eks:DescribeCluster"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ManageAccessEntriesAndAssociations"
    effect = "Allow"
    actions = [
      "eks:DescribeAccessEntry",
      "eks:UpdateAccessEntry",
      "eks:DeleteAccessEntry",
      "eks:AssociateAccessPolicy",
      "eks:DisassociateAccessPolicy",
      "eks:ListAssociatedAccessPolicies",
      "eks:ListAccessPolicies",
      "eks:TagResource",
      "eks:UntagResource"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_access" {
  name   = "container-platform-eks-access-policy"
  policy = data.aws_iam_policy_document.eks_access.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.eks_access.name
  policy_arn = aws_iam_policy.eks_access.arn
}
