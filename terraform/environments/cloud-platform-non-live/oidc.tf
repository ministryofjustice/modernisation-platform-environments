# OIDC resources
# OIDC Provider is created as part of MP bootstrapping, we only need to create additional roles.

# OIDC Provider for GitHub Actions Admin
module "github_actions_development_cluster_oidc_role" {
  source              = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=b40748ec162b446f8f8d282f767a85b6501fd192" # v4.0.0
  github_repositories = ["ministryofjustice/cloud-platform-github-workflows"]
  role_name           = "github-actions-development-cluster"
  policy_jsons        = [data.aws_iam_policy_document.github_actions_development_cluster_oidc_policy.json]
  subject_claim       = "*"
  #   subject_claim       = "workflow:development-cluster-deploy.yml"
  tags = merge({ "Name" = "GitHub Actions Development Cluster Role" }, local.tags)
}

data "aws_iam_policy_document" "github_actions_development_cluster_oidc_policy" {
  statement {
    sid    = "EKSClusterAndAccessManagement"
    effect = "Allow"
    actions = [
      "eks:CreateCluster",
      "eks:DeleteCluster",
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:UpdateClusterConfig",
      "eks:UpdateClusterVersion",
      "eks:TagResource",
      "eks:UntagResource",
      "eks:CreateAccessEntry",
      "eks:DeleteAccessEntry",
      "eks:DescribeAccessEntry",
      "eks:ListAccessEntries",
      "eks:AssociateAccessPolicy",
      "eks:DisassociateAccessPolicy",
      "eks:ListAccessPolicies"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EKSNodegroupAndAddonManagement"
    effect = "Allow"
    actions = [
      "eks:CreateNodegroup",
      "eks:DeleteNodegroup",
      "eks:DescribeNodegroup",
      "eks:ListNodegroups",
      "eks:UpdateNodegroupConfig",
      "eks:UpdateNodegroupVersion",
      "eks:CreateAddon",
      "eks:DeleteAddon",
      "eks:DescribeAddon",
      "eks:DescribeAddonVersions",
      "eks:ListAddons",
      "eks:UpdateAddon"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IAMForEKSAndIRSA"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:ListRoles",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:UpdateAssumeRolePolicy",
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:ListOpenIDConnectProviders",
      "iam:PassRole"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "VPCAndEC2Networking"
    effect = "Allow"
    actions = [
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:CreateRouteTable",
      "ec2:DeleteRouteTable",
      "ec2:CreateRoute",
      "ec2:AssociateRouteTable",
      "ec2:DisassociateRouteTable",
      "ec2:CreateInternetGateway",
      "ec2:AttachInternetGateway",
      "ec2:DetachInternetGateway",
      "ec2:DeleteInternetGateway",
      "ec2:CreateNatGateway",
      "ec2:DeleteNatGateway",
      "ec2:AllocateAddress",
      "ec2:ReleaseAddress",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:Describe*",
      "ec2:ModifyVpcAttribute"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "LoadBalancing"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Modify*",
      "elasticloadbalancing:Describe*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CloudWatchLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy",
      "logs:Describe*",
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SupportingReadOnly"
    effect = "Allow"
    actions = [
      "autoscaling:Describe*",
      "ecr:GetAuthorizationToken",
      "ecr:DescribeRepositories",
      "ecr:DescribeImages",
      "ecr:ListImages"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DevelopmentClusterStateBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      module.development-cluster-state-bucket[0].bucket.arn,
      "${module.development-cluster-state-bucket[0].bucket.arn}/*"
    ]
  }

  statement {
    sid    = "DevelopmentClusterStateBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [aws_kms_key.development_cluster_s3_state_bucket[0].arn]
  }
  statement {
    sid    = "AllowOIDCToAssumeRoles"
    effect = "Allow"
    resources = [
      format("arn:aws:iam::%s:role/modify-dns-records", local.environment_management.account_ids["core-network-services-production"]),
      format("arn:aws:iam::%s:role/modernisation-account-limited-read-member-access", local.environment_management.modernisation_platform_account_id),
      format("arn:aws:iam::%s:role/ModernisationPlatformSSOReadOnly", local.environment_management.aws_organizations_root_account_id),
      # the following are required as cooker have development accounts but are in the sandbox vpc
      local.application_name == "cooker" ? format("arn:aws:iam::%s:role/member-delegation-house-sandbox", local.environment_management.account_ids["core-vpc-sandbox"]) : format("arn:aws:iam::%s:role/modernisation-account-limited-read-member-access", local.environment_management.modernisation_platform_account_id)
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [data.aws_organizations_organization.root_account.id]
    }
    actions = ["sts:AssumeRole"]
  }
}
