# Roles to allow cloud-platform-live to make eks changes
# Enables the container-platform-environments repo to manage eks access entries across cluster accounts.
#
# Split by privilege (ministryofjustice/cloud-platform#8612): a WRITE role
# (ContainerPlatformEKSAccess, mutating actions, for the identity-apply path)
# and a READ-ONLY role (ContainerPlatformEKSAccessReadOnly, List/Describe only,
# for the identity-plan path). Each is trusted by a specific OIDC role ARN via
# an aws:PrincipalArn string condition, not the account root. The ARN strings
# (local.cp_identity_{apply,plan}_role_arn) are used because the OIDC roles only
# exist in cloud-platform-live while these roles are created in every account.

# WRITE trust: only the identity-apply OIDC role may assume the write role.
data "aws_iam_policy_document" "trust_write" {
  statement {
    sid     = "AllowSourceAccountAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["cloud-platform-live"]}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"
      values   = [local.cp_identity_apply_role_arn]
    }
  }
}

# READ-ONLY trust: only the identity-plan OIDC role may assume the read-only role.
data "aws_iam_policy_document" "trust_readonly" {
  statement {
    sid     = "AllowSourceAccountAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids["cloud-platform-live"]}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"
      values   = [local.cp_identity_plan_role_arn]
    }
  }
}

resource "aws_iam_role" "eks_access" {
  name               = "ContainerPlatformEKSAccess"
  assume_role_policy = data.aws_iam_policy_document.trust_write.json
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

# Read-only variant for the identity-plan path. Allows only non-mutating EKS
# access-entry reads plus iam:ListRoles (needed by the CPE data.aws_iam_roles
# lookup so plan can resolve principal ARNs). No Create/Update/Delete/Associate/
# Disassociate/Tag/Untag — those stay exclusive to the write role above.
resource "aws_iam_role" "eks_access_readonly" {
  name               = "ContainerPlatformEKSAccessReadOnly"
  assume_role_policy = data.aws_iam_policy_document.trust_readonly.json
}

data "aws_iam_policy_document" "eks_access_readonly" {
  statement {
    sid    = "DiscoverPermissionSetRoles"
    effect = "Allow"
    actions = [
      "iam:ListRoles"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ReadAccessEntriesOnApprovedClusters"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListAccessEntries",
      "eks:DescribeAccessEntry",
      "eks:ListAssociatedAccessPolicies",
      "eks:ListAccessPolicies"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "eks_access_readonly" {
  name   = "container-platform-eks-access-readonly-policy"
  policy = data.aws_iam_policy_document.eks_access_readonly.json
}

resource "aws_iam_role_policy_attachment" "attach_readonly" {
  role       = aws_iam_role.eks_access_readonly.name
  policy_arn = aws_iam_policy.eks_access_readonly.arn
}
