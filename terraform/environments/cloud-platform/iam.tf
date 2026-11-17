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
    resources = ["arn:aws:s3:::${terraform.workspace}-tf-state/*"]
  }
}

resource "aws_iam_policy" "user_terraform_plan_policy" {
  count  = local.state_bucket_enabled ? 1 : 0
  name   = "user-terraform-plan-policy"
  policy = data.aws_iam_policy_document.user_terraform_plan_policy[0].json
}

# Read-only permissions for Terraform plan
#Limit resource access to the current workspace
data "aws_iam_policy_document" "user_terraform_plan_resources_policy" {
  count = local.state_bucket_enabled ? 1 : 0

  # EC2 and networking resources
  statement {
    sid    = "EC2ReadOnly"
    effect = "Allow"

    actions = [
      "ec2:Describe*"
    ]
    #Change resoures to limit to each workspace

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

  # S3 bucket configuration reads
  statement {
    sid    = "S3ReadOnly"
    effect = "Allow"

    actions = [
      "s3:GetBucket*",
      "s3:ListBucket",
      "s3:GetObject*",
      "s3:GetEncryptionConfiguration",
      "s3:GetVersioning",
      "s3:ListBucketVersions",
      "s3:GetLifecycleConfiguration",
      "s3:GetACL"
    ]

    resources = ["*"]
  }

  # DynamoDB table reads
  statement {
    sid    = "DynamoDBReadOnly"
    effect = "Allow"

    actions = [
      "dynamodb:Describe*",
      "dynamodb:List*",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]

    resources = ["*"]
  }

  # KMS key policy and rotation reads
  statement {
    sid    = "KMSReadOnly"
    effect = "Allow"

    actions = [
      "kms:Describe*",
      "kms:List*",
      "kms:GetKey*",
      "kms:GetRotationStatus",
      "kms:GetPublicKey"
    ]

    resources = ["*"]
  }

  # DMS (Database Migration Service) reads
  statement {
    sid    = "DMSReadOnly"
    effect = "Allow"

    actions = [
      "dms:Describe*",
      "dms:List*",
      "dms:TestConnection"
    ]

    resources = ["*"]
  }

  # ElastiCache reads
  statement {
    sid    = "ElastiCacheReadOnly"
    effect = "Allow"

    actions = [
      "elasticache:Describe*",
      "elasticache:List*"
    ]

    resources = ["*"]
  }

  # EFS (Elastic File System) reads
  statement {
    sid    = "EFSReadOnly"
    effect = "Allow"

    actions = [
      "elasticfilesystem:Describe*",
      "elasticfilesystem:List*"
    ]

    resources = ["*"]
  }

  # Elasticsearch reads
  statement {
    sid    = "ElasticsearchReadOnly"
    effect = "Allow"

    actions = [
      "es:Describe*",
      "es:List*",
      "es:Get*"
    ]

    resources = ["*"]
  }

  # ECR (Elastic Container Registry) reads
  statement {
    sid    = "ECRReadOnly"
    effect = "Allow"

    actions = [
      "ecr:Describe*",
      "ecr:List*",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    resources = ["*"]
  }

  # API Gateway, ACM, Cognito reads
  statement {
    sid    = "APIAndDataServicesReadOnly"
    effect = "Allow"

    actions = [
      "acm:Describe*",
      "acm:List*",
      "apigateway:Get*",
      "apigateway:List*",
      "cognito-idp:Describe*",
      "cognito-idp:List*",
      "cognito-idp:Get*",
      "firehose:Describe*",
      "firehose:List*",
      "kinesis:Describe*",
      "kinesis:List*",
      "athena:Get*",
      "athena:List*",
      "glue:Get*",
      "glue:List*"
    ]

    resources = ["*"]
  }

  # Application Auto Scaling reads
  statement {
    sid    = "ApplicationAutoScalingReadOnly"
    effect = "Allow"

    actions = [
      "application-autoscaling:Describe*",
      "application-autoscaling:List*"
    ]

    resources = ["*"]
  }

  # MQ (Message Queue) reads
  statement {
    sid    = "MQReadOnly"
    effect = "Allow"

    actions = [
      "mq:Describe*",
      "mq:List*"
    ]

    resources = ["*"]
  }

  # WAFv2 reads
  statement {
    sid    = "WAFv2ReadOnly"
    effect = "Allow"

    actions = [
      "wafv2:Describe*",
      "wafv2:List*",
      "wafv2:Get*"
    ]

    resources = ["*"]
  }

  # Kendra reads
  statement {
    sid    = "KendraReadOnly"
    effect = "Allow"

    actions = [
      "kendra:Describe*",
      "kendra:List*",
      "kendra:Query"
    ]

    resources = ["*"]
  }

  # CloudFront reads
  statement {
    sid    = "CloudFrontReadOnly"
    effect = "Allow"

    actions = [
      "cloudfront:Describe*",
      "cloudfront:Get*",
      "cloudfront:List*"
    ]

    resources = ["*"]
  }

  # GuardDuty reads
  statement {
    sid    = "GuardDutyReadOnly"
    effect = "Allow"

    actions = [
      "guardduty:Get*",
      "guardduty:List*",
      "guardduty:Describe*"
    ]

    resources = ["*"]
  }

  # Network Firewall reads
  statement {
    sid    = "NetworkFirewallReadOnly"
    effect = "Allow"

    actions = [
      "network-firewall:Describe*",
      "network-firewall:List*"
    ]

    resources = ["*"]
  }

  # Secrets Manager reads
  statement {
    sid    = "SecretsManagerReadOnly"
    effect = "Allow"

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecrets",
      "secretsmanager:ListSecretVersionIds"
    ]

    resources = ["*"]
  }

  # Lambda reads
  statement {
    sid    = "LambdaReadOnly"
    effect = "Allow"

    actions = [
      "lambda:Describe*",
      "lambda:Get*",
      "lambda:List*"
    ]

    resources = ["*"]
  }

  # CloudWatch Logs reads
  statement {
    sid    = "LogsReadOnly"
    effect = "Allow"

    actions = [
      "logs:Describe*",
      "logs:List*",
      "logs:Get*"
    ]

    resources = ["*"]
  }

  # SNS reads
  statement {
    sid    = "SNSReadOnly"
    effect = "Allow"

    actions = [
      "sns:Describe*",
      "sns:Get*",
      "sns:List*"
    ]

    resources = ["*"]
  }

  # SQS reads
  statement {
    sid    = "SQSReadOnly"
    effect = "Allow"

    actions = [
      "sqs:Describe*",
      "sqs:Get*",
      "sqs:List*"
    ]

    resources = ["*"]
  }

  # Systems Manager reads
  statement {
    sid    = "SSMReadOnly"
    effect = "Allow"

    actions = [
      "ssm:Describe*",
      "ssm:Get*",
      "ssm:List*"
    ]

    resources = ["*"]
  }

  # Backup reads
  statement {
    sid    = "BackupReadOnly"
    effect = "Allow"

    actions = [
      "backup:Describe*",
      "backup:Get*",
      "backup:List*"
    ]

    resources = ["*"]
  }

  # Elastic Load Balancing reads
  statement {
    sid    = "ELBReadOnly"
    effect = "Allow"

    actions = [
      "elasticloadbalancing:Describe*"
    ]

    resources = ["*"]
  }

  # Access Analyzer reads
  statement {
    sid    = "AccessAnalyzerReadOnly"
    effect = "Allow"

    actions = [
      "access-analyzer:Describe*",
      "access-analyzer:Get*",
      "access-analyzer:List*"
    ]

    resources = ["*"]
  }

  # CloudTrail reads
  statement {
    sid    = "CloudTrailReadOnly"
    effect = "Allow"

    actions = [
      "cloudtrail:DescribeTrails",
      "cloudtrail:GetEventSelectors",
      "cloudtrail:GetTrailStatus",
      "cloudtrail:ListTags"
    ]

    resources = ["*"]
  }

  # CloudWatch reads
  statement {
    sid    = "CloudWatchReadOnly"
    effect = "Allow"

    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListTagsForResource"
    ]

    resources = ["*"]
  }

  # EventBridge reads
  statement {
    sid    = "EventBridgeReadOnly"
    effect = "Allow"

    actions = [
      "events:DescribeRule",
      "events:ListTagsForResource",
      "events:ListTargetsByRule"
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
  count  = local.state_bucket_enabled ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-cross-account-access?ref=v4.0.2"

  account_id           = local.environment_management.account_ids["cloud-platform-live"]
  role_name            = "user-terraform-plan"
  policy_arn           = aws_iam_policy.user_terraform_plan_policy[0].arn
  restricted_role_name = "github-actions-cp3-user-terraform-plan"
}

# Attach custom Terraform plan resources policy after creating the cross-account plan role
resource "aws_iam_role_policy_attachment" "user_terraform_plan_resources" {
  count      = local.state_bucket_enabled ? 1 : 0
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

  # S3 resources
  statement {
    sid    = "S3FullAccess"
    effect = "Allow"

    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::*"
    ]
  }

  # IAM user and policy management
  statement {
    sid    = "IAMUserManagement"
    effect = "Allow"

    actions = [
      "iam:GetUser",
      "iam:CreateUser",
      "iam:DeleteUser",
      "iam:UpdateUser",
      "iam:ListAccessKeys",
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:PutUserPolicy",
      "iam:GetUserPolicy",
      "iam:DeleteUserPolicy",
      "iam:DetachUserPolicy",
      "iam:ListGroupsForUser",
      "iam:PutUserPermissionsBoundary",
      "iam:GetPolicy",
      "iam:ListEntitiesForPolicy",
      "iam:CreatePolicyVersion",
      "iam:GetPolicyVersion",
      "iam:DeleteUserPermissionsBoundary",
      "iam:Tag*",
      "iam:Untag*",
      "iam:ListPolicyTags",
      "iam:ListRoleTags",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListAccountAliases",
      "iam:GetGroup",
      "iam:ListAttachedGroupPolicies",
      "iam:AttachUserPolicy"
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  # IAM role management
  statement {
    sid    = "IAMRoleManagement"
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetRole",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:Tag*",
      "iam:Untag*",
      "iam:ListInstanceProfilesForRole",
      "iam:DeleteRolePolicy",
      "iam:DeleteRole",
      "iam:ListRoleTags"
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
    ]
  }

  # IAM policy lifecycle management
  statement {
    sid    = "IAMPolicyLifecycle"
    effect = "Allow"

    actions = [
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:ListPolicyVersions",
      "iam:SetDefaultPolicyVersion"
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/*"
    ]
  }

  # OIDC provider management
  statement {
    sid    = "OIDCProviderManagement"
    effect = "Allow"

    actions = [
      "iam:GetOpenIDConnectProvider",
      "iam:ListOpenIDConnectProviders",
      "iam:UpdateOpenIDConnectProviderThumbprint"
    ]

    resources = [
      "*"
    ]
  }

  # EC2 + networking resources
  statement {
    sid    = "EC2Access"
    effect = "Allow"

    actions = [
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateNetworkInterface",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteNetworkInterface",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteNetworkInterfacePermission",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroupReferences",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeStaleSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DetachNetworkInterface",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
      "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
      "ec2:TerminateInstances",
      "ec2:Describe*",
      "ec2:*TransitGateway*",
      "autoscaling:Describe*"
    ]

    resources = [
      "*"
    ]
  }

  # EKS clusters
  statement {
    sid    = "EKSFullAccess"
    effect = "Allow"

    actions = [
      "eks:*",
      "eks:DescribeCluster"
    ]

    resources = [
      "*"
    ]
  }

  # EKS role assumption - narrowly scoped PassRole for cluster and node roles
  statement {
    sid    = "EKSPassRole"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*eks*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*cluster*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*node*"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["eks.amazonaws.com"]
    }
  }

  # RDS
  statement {
    sid    = "RDSFullAccess"
    effect = "Allow"

    actions = [
      "rds:*"
    ]

    resources = [
      "*"
    ]
  }

  # DMS (Database Migration Service)
  statement {
    sid    = "DMSFullAccess"
    effect = "Allow"

    actions = [
      "dms:*"
    ]

    resources = [
      "*"
    ]
  }

  # KMS
  statement {
    sid    = "KMSFullAccess"
    effect = "Allow"

    actions = [
      "kms:*"
    ]

    resources = [
      "*"
    ]
  }

  # ElastiCache
  statement {
    sid    = "ElastiCacheFullAccess"
    effect = "Allow"

    actions = [
      "elasticache:*"
    ]

    resources = [
      "*"
    ]
  }

  # Elastic File System
  statement {
    sid    = "EFSFullAccess"
    effect = "Allow"

    actions = [
      "elasticfilesystem:*"
    ]

    resources = [
      "*"
    ]
  }

  # DynamoDB
  statement {
    sid    = "DynamoDBFullAccess"
    effect = "Allow"

    actions = [
      "dynamodb:*"
    ]

    resources = [
      "*"
    ]
  }

  # Elasticsearch
  statement {
    sid    = "ElasticsearchFullAccess"
    effect = "Allow"

    actions = [
      "es:*"
    ]

    resources = [
      "*"
    ]
  }

  # ECR (Elastic Container Registry)
  statement {
    sid    = "ECRFullAccess"
    effect = "Allow"

    actions = [
      "ecr:*"
    ]

    resources = [
      "*"
    ]
  }

  # API Gateway, Cognito, Firehose, Kinesis, Athena, Glue
  statement {
    sid    = "APIAndDataServices"
    effect = "Allow"

    actions = [
      "apigateway:*",
      "cognito-idp:*",
      "execute-api:*",
      "firehose:*",
      "iam:CreateServiceLinkedRole",
      "kinesis:*",
      "athena:*",
      "glue:*"
    ]

    resources = [
      "*"
    ]
  }

  # ACM (with specific actions from Concourse)
  statement {
    sid    = "ACMFullAccess"
    effect = "Allow"

    actions = [
      "acm:*",
      "acm:DeleteCertificate",
      "acm:DescribeCertificate",
      "acm:ListTagsForCertificate",
      "acm:RequestCertificate"
    ]

    resources = [
      "*"
    ]
  }

  # Application Auto Scaling
  statement {
    sid    = "ApplicationAutoScaling"
    effect = "Allow"

    actions = [
      "application-autoscaling:RegisterScalableTarget",
      "application-autoscaling:DescribeScalableTargets",
      "application-autoscaling:PutScalingPolicy",
      "application-autoscaling:DescribeScalingPolicies",
      "application-autoscaling:DeleteScalingPolicy",
      "application-autoscaling:DeregisterScalableTarget",
      "application-autoscaling:TagResource",
      "application-autoscaling:ListTagsForResource"
    ]

    resources = [
      "*"
    ]
  }

  # MQ (Message Queue)
  statement {
    sid    = "MQFullAccess"
    effect = "Allow"

    actions = [
      "mq:*"
    ]

    resources = [
      "*"
    ]
  }

  # WAFv2
  statement {
    sid    = "WAFv2FullAccess"
    effect = "Allow"

    actions = [
      "wafv2:*"
    ]

    resources = [
      "*"
    ]
  }

  # Kendra (search service)
  statement {
    sid    = "KendraFullAccess"
    effect = "Allow"

    actions = [
      "kendra:*"
    ]

    resources = [
      "*"
    ]
  }

  # GuardDuty (security)
  statement {
    sid    = "GuardDutyManagement"
    effect = "Allow"

    actions = [
      "guardduty:CreateMalwareProtectionPlan",
      "guardduty:DeleteMalwareProtectionPlan",
      "guardduty:UpdateMalwareProtectionPlan",
      "guardduty:GetMalwareProtectionPlan",
      "guardduty:TagResource",
      "guardduty:ListTagsForResource"
    ]

    resources = [
      "*"
    ]
  }

  # Network Firewall
  statement {
    sid    = "NetworkFirewall"
    effect = "Allow"

    actions = [
      "network-firewall:*"
    ]

    resources = [
      "*"
    ]
  }

  # Route 53
  statement {
    sid    = "Route53FullAccess"
    effect = "Allow"

    actions = [
      "route53:*"
    ]

    resources = [
      "*"
    ]
  }

  # CloudFront
  statement {
    sid    = "CloudFrontFullAccess"
    effect = "Allow"

    actions = [
      "cloudfront:*"
    ]

    resources = [
      "*"
    ]
  }

  # Secrets Manager
  statement {
    sid    = "SecretsManagerFullAccess"
    effect = "Allow"

    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecrets",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:PutResourcePolicy",
      "secretsmanager:PutSecretValue",
      "secretsmanager:TagResource",
      "secretsmanager:UntagResource",
      "secretsmanager:UpdateSecret",
      "secretsmanager:ValidateResourcePolicy",
    ]

    resources = [
      "*"
    ]
  }

  # Lambda
  statement {
    sid    = "LambdaFullAccess"
    effect = "Allow"

    actions = [
      "lambda:*",
      "lambda:CreateCodeSigningConfig",
      "lambda:CreateEventSourceMapping",
      "lambda:GetAccountSettings",
      "lambda:ListCodeSigningConfigs",
      "lambda:ListEventSourceMappings",
      "lambda:ListLayerVersions",
      "lambda:ListLayers"
    ]

    resources = [
      "*"
    ]
  }

  # CloudWatch Logs
  statement {
    sid    = "LogsFullAccess"
    effect = "Allow"

    actions = [
      "logs:*"
    ]

    resources = [
      "*"
    ]
  }

  # SNS
  statement {
    sid    = "SNSFullAccess"
    effect = "Allow"

    actions = [
      "sns:*"
    ]

    resources = [
      "*"
    ]
  }

  # SQS
  statement {
    sid    = "SQSFullAccess"
    effect = "Allow"

    actions = [
      "sqs:*"
    ]

    resources = [
      "*"
    ]
  }

  # Systems Manager
  statement {
    sid    = "SSMFullAccess"
    effect = "Allow"

    actions = [
      "ssm:*",
      "ssm:DescribeAssociation",
      "ssm:GetDocument"
    ]

    resources = [
      "*"
    ]
  }

  # Backup
  statement {
    sid    = "BackupFullAccess"
    effect = "Allow"

    actions = [
      "backup:*",
      "backup-storage:*"
    ]

    resources = [
      "*"
    ]
  }

  # Elastic Load Balancing
  statement {
    sid    = "ELBFullAccess"
    effect = "Allow"

    actions = [
      "elasticloadbalancing:*"
    ]

    resources = [
      "*"
    ]
  }

  # Access Analyzer
  statement {
    sid    = "AccessAnalyzerFullAccess"
    effect = "Allow"

    actions = [
      "access-analyzer:*"
    ]

    resources = [
      "*"
    ]
  }

  # CloudTrail
  statement {
    sid    = "CloudTrailFullAccess"
    effect = "Allow"

    actions = [
      "cloudtrail:AddTags",
      "cloudtrail:DescribeTrails",
      "cloudtrail:GetEventSelectors",
      "cloudtrail:GetTrailStatus",
      "cloudtrail:ListTags",
      "cloudtrail:RemoveTags",
      "cloudtrail:UpdateTrail"
    ]

    resources = ["*"]
  }

  # CloudWatch
  statement {
    sid    = "CloudWatchFullAccess"
    effect = "Allow"

    actions = [
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListTagsForResource",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:TagResource",
      "cloudwatch:UntagResource"
    ]

    resources = ["*"]
  }

  # EventBridge
  statement {
    sid    = "EventBridgeFullAccess"
    effect = "Allow"

    actions = [
      "events:DescribeRule",
      "events:ListTagsForResource",
      "events:ListTargetsByRule",
      "events:TagResource",
      "events:UntagResource"
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

    resources = [
      "*"
    ]
  }

  # Explicitly deny modifying the workflow automation policies themselves
  # Prevents the apply role from replacing its own permissions via CreatePolicyVersion
  statement {
    sid    = "DenyModifyWorkflowPolicies"
    effect = "Deny"

    actions = [
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:DeletePolicy"
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/user-terraform-plan-policy",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/user-terraform-apply-policy",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${terraform.workspace}-plan-resources-policy",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${terraform.workspace}-apply-resources-policy"
    ]
  }
}

resource "aws_iam_policy" "user_terraform_apply_resources_policy" {
  count = local.state_bucket_enabled ? 1 : 0

  name   = "${terraform.workspace}-apply-resources-policy"
  policy = data.aws_iam_policy_document.user_terraform_apply_resources_policy[0].json
}

# Create cross account apply role with initial user terraform apply policy
module "user_terraform_apply" {
  count  = local.state_bucket_enabled ? 1 : 0
  source = "github.com/ministryofjustice/modernisation-platform-terraform-cross-account-access?ref=v4.0.2"

  account_id           = local.environment_management.account_ids["cloud-platform-live"]
  role_name            = "user-terraform-apply"
  policy_arn           = aws_iam_policy.user_terraform_apply_policy[0].arn
  restricted_role_name = "github-actions-cp3-user-terraform-apply"
}

# Attach custom Terraform resources policy to the cross-account apply role
resource "aws_iam_role_policy_attachment" "user_terraform_apply_resources" {
  count = local.state_bucket_enabled ? 1 : 0

  role       = element(split("/", module.user_terraform_apply[0].role_arn), 1)
  policy_arn = aws_iam_policy.user_terraform_apply_resources_policy[0].arn
}


