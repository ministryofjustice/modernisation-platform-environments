# OIDC resources
# OIDC Provider is created as part of MP bootstrapping, we only need to create additional roles.

# OIDC Role for GitHub Actions - Development Cluster Deployment
module "github_actions_development_cluster_oidc_role" {
  count               = local.environment == "development" ? 1 : 0
  source              = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=b40748ec162b446f8f8d282f767a85b6501fd192" # v4.0.0
  github_repositories = ["ministryofjustice/cloud-platform-github-workflows"]
  role_name           = "github-actions-development-cluster"
  policy_jsons        = [data.aws_iam_policy_document.github_actions_development_cluster_oidc_policy[0].json]
  subject_claim       = "ref:refs/heads/*"
  tags                = merge({ "Name" = "GitHub Actions Development Cluster Role" }, local.tags)
}

data "aws_iam_policy_document" "github_actions_development_cluster_oidc_policy" {
  count = local.environment == "development" ? 1 : 0
  statement {
    sid    = "EKSClusterManagement"
    effect = "Allow"
    actions = [
      "eks:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IAMForEKSAndIRSA"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:CreatePolicy",
      "iam:DeleteRole",
      "iam:Get*",
      "iam:ListRoles",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:DeletePolicy",
      "iam:UpdateAssumeRolePolicy",
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:ListOpenIDConnectProviders",
      "iam:TagOpenIDConnectProvider",
      "iam:PassRole",
      "iam:TagRole",
      "iam:TagPolicy"
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
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:*RouteTable*",
      "ec2:CreateVpcEndpoint",
      "ec2:DeleteVpcEndpoints",
      "ec2:CreateVpcEndpointServiceConfiguration",
      "ec2:DeleteVpcEndpointServiceConfigurations",
      "ec2:CreateVpcPeeringConnection",
      "ec2:DeleteVpcPeeringConnection",
      "ec2:DisableSerialConsoleAccess",
      "ec2:EnableSerialConsoleAccess",
      "ec2:GetSerialConsoleAccessStatus",
      "ec2:ModifyVpc*",
      "ec2:Describe*",
      "ec2:*NetworkAcl*",
      "ec2:*FlowLogs",
      "ec2:*SecurityGroup*",
      "ec2:*KeyPair*",
      "ec2:*Tags*",
      "ec2:*Volume*",
      "ec2:*Snapshot*",
      "ec2:*Ebs*",
      "ec2:*NetworkInterface*",
      "ec2:*Address*",
      "ec2:*Image*",
      "ec2:*Event*",
      "ec2:*Instance*",
      "ec2:*CapacityReservation*",
      "ec2:*Fleet*",
      "ec2:Get*",
      "ec2:SendDiagnosticInterrupt",
      "ec2:*LaunchTemplate*",
      "ec2:*PlacementGroup*",
      "ec2:*IdFormat*",
      "ec2:*Spot*",
      "ec2:*InternetGateway*",
      "ec2:*NatGateway*",
      "ec2:*TransitGatewayVpcAttachment*",
      "ec2:*ManagedPrefixList*"
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
    sid    = "DevelopmentClusterKMSKey"
    effect = "Allow"
    actions = [
      "kms:*"
    ]
    resources = ["*"]
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
