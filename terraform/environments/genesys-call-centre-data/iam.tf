locals {
  # Workspace name = genesys-call-centre-data-development
  # Create a local variable that stores the last part of the workspace name
  bt_roles = {
    development = [
      "arn:aws:iam::572734708359:role/a3s-di-core-int-moj-ingestion-role-eu-west-2-demo",
      "arn:aws:iam::572734708359:role/a3s-di-outbound-int-moj-ingestion-role-eu-west-2-demo",
      "arn:aws:iam::572734708359:role/a3s-di-survey-int-moj-ingestion-role-eu-west-2-demo",
      "arn:aws:iam::572734708359:role/a3s-di-sta-int-moj-ingestion-role-eu-west-2-demo",
      "arn:aws:iam::572734708359:role/a3s-di-wfm-int-moj-ingestion-role-eu-west-2-demo",
      "arn:aws:iam::572734708359:role/a3s-di-ivr-int-moj-ingestion-role-eu-west-2-demo",
      "arn:aws:iam::572734708359:role/a3s-di-qm-int-moj-ingestion-role-eu-west-2-demo",
    ]
    production = [
      "arn:aws:iam::572734708359:role/a3s-di-core-int-moj-ingestion-role-eu-west-2-demo",
    ]
  }
}

# This is the role that BT will assume to upload files into the S3 bucket
resource "aws_iam_role" "cross_account_assume_role" {
  name = "bt-genesys-s3-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = local.bt_roles[local.environment]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Create a policy to allow the role to write and list to/on a specific S3 bucket
resource "aws_iam_policy" "cross_account_assume_role_policy" {
  name = "bt-genesys-s3-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3_bucket_staging.bucket.arn,
          "${module.s3_bucket_staging.bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "cross_account_assume_role_policy_attachment" {
  role       = aws_iam_role.cross_account_assume_role.name
  policy_arn = aws_iam_policy.cross_account_assume_role_policy.arn
}

# Amazon Managed Workflows for Apache Airflow (MWAA)
data "aws_iam_policy_document" "mwaa_execution_policy" {
  statement {
    effect  = "Deny"
    actions = ["s3:ListAllMyBuckets"]
    resources = [
      "arn:aws:s3:::mojap-compute-${local.environment}-mwaa",
      "arn:aws:s3:::mojap-compute-${local.environment}-mwaa/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::mojap-compute-${local.environment}-mwaa",
      "arn:aws:s3:::mojap-compute-${local.environment}-mwaa/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:GetLogRecord",
      "logs:GetLogGroupFields",
      "logs:GetQueryResults"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:airflow-${local.environment}-*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetAccountPublicAccessBlock"]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage"
    ]
    resources = ["arn:aws:sqs:${data.aws_region.current.name}:*:airflow-celery-*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt"
    ]
    resources = [module.mwaa_kms.key_arn]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values = [
        "s3.${data.aws_region.current.name}.amazonaws.com",
        "sqs.${data.aws_region.current.name}.amazonaws.com"
      ]
    }
  }
  statement {
    sid       = "AllowEKSDescribeCluster"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [module.eks.cluster_arn]
  }
}

module "mwaa_execution_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.52.2"

  name   = "mwaa-execution"
  policy = data.aws_iam_policy_document.mwaa_execution_policy.json

  tags = local.tags
}

module "mwaa_execution_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.52.2"

  create_role = true

  role_name         = "mwaa-execution"
  role_requires_mfa = false

  trusted_role_services = [
    "airflow.amazonaws.com",
    "airflow-env.amazonaws.com"
  ]

  custom_role_policy_arns = [module.mwaa_execution_iam_policy.arn]

  tags = local.tags
}