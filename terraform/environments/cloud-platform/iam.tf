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


# Custom policy for plan role: read-only access to Terraform state
data "aws_iam_policy_document" "user_terraform_plan_policy" {
  count = local.state_bucket_enabled ? 1 : 0
  #Read Terraform state
  statement {
    sid    = "TerraformStateReadOnly"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::${terraform.workspace}-tf-state/*"]
  }
  # List Terraform state buckets objects
  statement {
    sid    = "TerraformStateBucketListings"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::${terraform.workspace}-tf-state"]
  }

   # Allow Terraform to acquire and release S3 locks
  statement {
    sid    = "TerraformStateLockfileAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${terraform.workspace}-tf-state/*.tflock"
    ]
  }

  statement {
    sid    = "KMSKeyDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "user_terraform_plan_policy" {
  count = local.state_bucket_enabled ? 1 : 0
  name   = "user-terraform-plan-policy"
  policy = data.aws_iam_policy_document.user_terraform_plan_policy[0].json
}

# Read-only permissions for Terraform plan
data "aws_iam_policy_document" "user_terraform_plan_resources_policy" {
  count = local.state_bucket_enabled ? 1 : 0

  # EC2 and networking resources
  statement {
    sid    = "EC2ReadOnly"
    effect = "Allow"

    actions = [
      "ec2:Describe*"
    ]

    resources = ["*"]
  }

  # EKS clusters
  statement {
    sid    = "EKSReadOnly"
    effect = "Allow"

    actions = [
      "eks:Describe*",
      "eks:List*"
    ]

    resources = ["*"]
  }

  # IAM resources
  statement {
    sid    = "IAMReadOnly"
    effect = "Allow"

    actions = [
      "iam:Get*",
      "iam:List*"
    ]

    resources = ["*"]
  }

  # RDS and Aurora
  statement {
    sid    = "RDSReadOnly"
    effect = "Allow"

    actions = [
      "rds:Describe*",
      "rds:ListTagsForResource"
    ]

    resources = ["*"]
  }

  # Route 53
  statement {
    sid    = "Route53ReadOnly"
    effect = "Allow"

    actions = [
      "route53:Get*",
      "route53:List*"
    ]

    resources = ["*"]
  }

  # KMS
  statement {
    sid    = "KMSReadOnly"
    effect = "Allow"

    actions = [
      "kms:DescribeKey",
      "kms:ListAliases",
      "kms:ListKeys"
    ]

    resources = ["*"]
  }

  # STS identity
  statement {
    sid    = "STSReadOnly"
    effect = "Allow"

    actions = [
      "sts:GetCallerIdentity"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "user_terraform_plan_resources_policy" {
  count  = local.state_bucket_enabled ? 1 : 0
  name   = "${terraform.workspace}-plan-resources-policy"
  policy = data.aws_iam_policy_document.user_terraform_plan_resources_policy[0].json
}


# Cross account module is used to create sts assume role for gh actions cp3 user-terraform-plan role in cp live using initial tf plan policy
module "user_terraform_plan" {
  count = local.state_bucket_enabled ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-cross-account-access?ref=03adcc52cd48a2679ea34800fa4eaf6f89db6eaf"
  
  account_id            = local.environment_management.account_ids["cloud-platform-live"]
  role_name             = "user-terraform-plan"
  policy_arn            = aws_iam_policy.user_terraform_plan_policy[0].arn
  restricted_role       = true
  restricted_role_name  = "github-actions-cp3-user-terraform-plan"
}

# Attach custom Terraform plan resources policy after creating the cross-account plan role
resource "aws_iam_role_policy_attachment" "user_terraform_plan_resources" {
  count = local.state_bucket_enabled ? 1 : 0
  role       = element(split("/", module.user_terraform_plan[0].role_arn), 1)
  policy_arn = aws_iam_policy.user_terraform_plan_resources_policy[0].arn
}



# Custom policy for apply role: read/write access to Terraform state
data "aws_iam_policy_document" "user_terraform_apply_policy" {
  count = local.state_bucket_enabled ? 1 : 0

  # Read and write Terraform state
  statement {
    sid    = "TerraformStateBucketReadWrite"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = [
      "arn:aws:s3:::${terraform.workspace}-tf-state/*"
    ]
  }

  # List Terraform state bucket objects
  statement {
    sid    = "TerraformStateBucketListings"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${terraform.workspace}-tf-state"
    ]
  }

  # KMS access for encrypted Terraform state
  statement {
    sid    = "KMSKeyAccess"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]

    resources = [
      aws_kms_key.state[0].arn
    ]
  }
}

resource "aws_iam_policy" "user_terraform_apply_policy" {
  count = local.state_bucket_enabled ? 1 : 0

  name   = "user-terraform-apply-policy"
  policy = data.aws_iam_policy_document.user_terraform_apply_policy[0].json
}


# Permissions for Terraform apply to manage AWS resources
data "aws_iam_policy_document" "user_terraform_apply_resources_policy" {
  count = local.state_bucket_enabled ? 1 : 0

  # EC2 + networking resources
  statement {
    sid    = "EC2FullAccess"
    effect = "Allow"

    actions = [
      "ec2:*"
    ]

    resources = ["*"]
  }

  # EKS clusters
  statement {
    sid    = "EKSFullAccess"
    effect = "Allow"

    actions = [
      "eks:*"
    ]

    resources = ["*"]
  }

  # IAM resources
  statement {
    sid    = "IAMFullAccess"
    effect = "Allow"

    actions = [
      "iam:*"
    ]

    resources = ["*"]
  }

  # RDS
  statement {
    sid    = "RDSFullAccess"
    effect = "Allow"

    actions = [
      "rds:*"
    ]

    resources = ["*"]
  }

  # Route 53
  statement {
    sid    = "Route53FullAccess"
    effect = "Allow"

    actions = [
      "route53:*"
    ]

    resources = ["*"]
  }

  # KMS
  statement {
    sid    = "KMSFullAccess"
    effect = "Allow"

    actions = [
      "kms:*"
    ]

    resources = ["*"]
  }

  # STS identity
  statement {
    sid    = "STSReadOnly"
    effect = "Allow"

    actions = [
      "sts:GetCallerIdentity"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "user_terraform_apply_resources_policy" {
  count = local.state_bucket_enabled ? 1 : 0

  name   = "${terraform.workspace}-apply-resources-policy"
  policy = data.aws_iam_policy_document.user_terraform_apply_resources_policy[0].json
}

# Create cross account apply role with initial user terraform apply policy
module "user_terraform_apply" {
  count = local.state_bucket_enabled ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-cross-account-access?ref=03adcc52cd48a2679ea34800fa4eaf6f89db6eaf"
  
  account_id            = local.environment_management.account_ids["cloud-platform-live"]
  role_name             = "user-terraform-apply"
  policy_arn            = aws_iam_policy.user_terraform_apply_policy[0].arn
  restricted_role       = true
  restricted_role_name  = "github-actions-cp3-user-terraform-apply"
}

# Attach custom Terraform resources policy to the cross-account apply role
resource "aws_iam_role_policy_attachment" "user_terraform_apply_resources" {
  count = local.state_bucket_enabled ? 1 : 0

  role       = element(split("/", module.user_terraform_apply[0].role_arn), 1)
  policy_arn = aws_iam_policy.user_terraform_apply_resources_policy[0].arn
}


