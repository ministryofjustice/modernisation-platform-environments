data "aws_iam_policy_document" "ecr_access" {
  statement {
    sid       = "AllowECRRegistryAccess"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [data.aws_region.current.region]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
  statement {
    sid    = "AllowECRRepositoryPermissions"
    effect = "Allow"
    actions = [
      "ecr:CreateRepository",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:SetRepositoryPolicy"
    ]
    resources = ["arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/*"]
  }
  statement {
    sid       = "DenyECRRepositoryPermissions"
    effect    = "Deny"
    actions   = ["ecr:DeleteRepository"]
    resources = ["arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/*"]
  }
  statement {
    sid    = "AllowECRImagePermissions"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = ["arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/*"]
  }
  statement {
    sid    = "DenyECRImagePermissions"
    effect = "Deny"
    actions = [
      "ecr:BatchDeleteImage",
      "ecr:DeleteImage",
    ]
    resources = ["arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/*"]
  }
  statement {
    sid    = "AllowECRKMSKeyPermissions"
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:DescribeKey"
    ]
    resources = [module.ecr_kms.key_arn]
  }
}

module "ecr_access_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.60.0"

  name_prefix = "ecr-access"

  policy = data.aws_iam_policy_document.ecr_access.json

  tags = local.tags
}

data "aws_iam_policy_document" "analytical_platform_terraform" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [module.terraform_s3_kms.key_arn]
  }
  statement {
    sid       = "AllowS3List"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.terraform_bucket.s3_bucket_arn]
  }
  statement {
    sid    = "AllowS3Write"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${module.terraform_bucket.s3_bucket_arn}/*"]
  }
}

module "analytical_platform_terraform_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.60.0"

  name_prefix = "analytical-platform-terraform"

  policy = data.aws_iam_policy_document.analytical_platform_terraform.json

  tags = local.tags
}

data "aws_iam_policy_document" "analytical_platform_github_actions" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      module.analytical_platform_terraform_iam_role.iam_role_arn,
      "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/analytical-platform-infrastructure-access"
    ]
  }
  statement {
    sid       = "AllowKMS"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [module.secrets_manager_common_kms.key_arn]
  }
  statement {
    sid     = "AllowSecretsManager"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      module.analytical_platform_compute_cluster_data_secret.secret_arn,
      module.airflow_github_app_secret.secret_arn
    ]
  }
  statement {
    sid     = "AllowEKS"
    effect  = "Allow"
    actions = ["eks:DescribeCluster"]
    resources = [
      "arn:aws:eks:eu-west-2:${local.environment_management.account_ids["analytical-platform-compute-development"]}:cluster/*",
      "arn:aws:eks:eu-west-2:${local.environment_management.account_ids["analytical-platform-compute-test"]}:cluster/*",
      "arn:aws:eks:eu-west-2:${local.environment_management.account_ids["analytical-platform-compute-production"]}:cluster/*"
    ]
  }
  statement {
    sid    = "AllowDynamodb"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:ListTables"
    ]
    resources = [module.analytical_platform_airflow_auto_approval_dynamodb_table.dynamodb_table_arn]
  }
}

module "analytical_platform_github_actions_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.60.0"

  name_prefix = "analytical-platform-github-actions"

  policy = data.aws_iam_policy_document.analytical_platform_github_actions.json

  tags = local.tags
}

data "aws_iam_policy_document" "data_engineering_datalake_access_github_actions" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    resources = [
      module.data_engineering_datalake_access_terraform_iam_role.iam_role_arn,
      "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/data-engineering-datalake-access",
      "arn:aws:iam::${local.environment_management.account_ids["electronic-monitoring-data-test"]}:role/analytical-platform-data-production-share-role",
      "arn:aws:iam::${local.environment_management.account_ids["electronic-monitoring-data-preproduction"]}:role/analytical-platform-data-production-share-role",
      "arn:aws:iam::${local.environment_management.account_ids["electronic-monitoring-data-production"]}:role/analytical-platform-data-production-share-role",
      "arn:aws:iam::${local.environment_management.account_ids["digital-prison-reporting-development"]}:role/analytical-platform-data-production-share-role",
      "arn:aws:iam::${local.environment_management.account_ids["digital-prison-reporting-test"]}:role/analytical-platform-data-production-share-role",
      "arn:aws:iam::${local.environment_management.account_ids["digital-prison-reporting-preproduction"]}:role/analytical-platform-data-production-share-role",
      "arn:aws:iam::${local.environment_management.account_ids["digital-prison-reporting-production"]}:role/analytical-platform-data-production-share-role",
      "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-development"]}:role/lakeformation-share-role",
      "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-preproduction"]}:role/lakeformation-share-role",
      "arn:aws:iam::${local.environment_management.account_ids["property-cafm-data-migration-production"]}:role/lakeformation-share-role",
    ]
  }
}

module "data_engineering_datalake_access_github_actions_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.60.0"

  name_prefix = "data-engineering-datalake-access-github-actions"

  policy = data.aws_iam_policy_document.data_engineering_datalake_access_github_actions.json

  tags = local.tags
}

data "aws_iam_policy_document" "data_engineering_datalake_access_terraform" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [module.terraform_s3_kms.key_arn]
  }
  statement {
    sid       = "AllowS3List"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.terraform_bucket.s3_bucket_arn]
  }
  statement {
    sid    = "AllowS3Write"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${module.terraform_bucket.s3_bucket_arn}/data-engineering-datalake-access/*"]
  }
}

module "data_engineering_datalake_access_terraform_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.60.0"

  name_prefix = "data-engineering-datalake-access-terraform"

  policy = data.aws_iam_policy_document.data_engineering_datalake_access_terraform.json

  tags = local.tags
}
