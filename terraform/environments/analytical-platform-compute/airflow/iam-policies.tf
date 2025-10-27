#trivy:ignore:AVD-AWS-0345: required as per documentation
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
    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:airflow-${local.environment}-*"]
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
    resources = ["arn:aws:sqs:${data.aws_region.current.region}:*:airflow-celery-*"]
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
        "s3.${data.aws_region.current.region}.amazonaws.com",
        "sqs.${data.aws_region.current.region}.amazonaws.com"
      ]
    }
  }
  statement {
    sid       = "AllowEKSDescribeCluster"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [data.aws_eks_cluster.apc_cluster.arn]
  }
  statement {
    sid       = "AllowSecretsManagerKMS"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_key.common_secrets_manager_kms.arn]
  }
  statement {
    sid       = "AllowSecretsManagerList"
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }
  statement {
    sid    = "AllowSecretsManager"
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:airflow/*"]
  }
}

module "mwaa_execution_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.59.0"

  name   = "mwaa-execution"
  policy = data.aws_iam_policy_document.mwaa_execution_policy.json

  tags = local.tags
}

data "aws_iam_policy_document" "mwaa_ses" {
  statement {
    sid    = "AllowSESSendRawEmail"
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = ["noreply@${local.environment_configuration.route53_zone}"]
    }
  }
}

module "mwaa_ses_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.59.0"

  name   = "mwaa-ses"
  policy = data.aws_iam_policy_document.mwaa_ses.json

  tags = local.tags
}

data "aws_iam_policy_document" "gha_moj_ap_airflow" {
  statement {
    sid    = "MWAAKMSAccess"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = [module.mwaa_kms.key_arn]
  }
  statement {
    sid    = "MWAABucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [module.mwaa_bucket.s3_bucket_arn]
  }
  statement {
    sid    = "MWAAS3WriteAccess"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${module.mwaa_bucket.s3_bucket_arn}/*"]
  }
  statement {
    sid       = "EKSAccess"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [data.aws_eks_cluster.apc_cluster.arn]
  }
}

module "gha_moj_ap_airflow_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.59.0"

  name = "github-actions-ministryofjustice-analytical-platform-airflow"

  policy = data.aws_iam_policy_document.gha_moj_ap_airflow.json

  tags = local.tags
}

data "aws_iam_policy_document" "gha_mojas_airflow" {
  statement {
    sid       = "EKSAccess"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [data.aws_eks_cluster.apc_cluster.arn]
  }
}

module "gha_mojas_airflow_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.59.0"

  name_prefix = "github-actions-mojas-airflow"

  policy = data.aws_iam_policy_document.gha_mojas_airflow.json

  tags = local.tags
}

data "aws_iam_policy_document" "create_airflow_token" {
  statement {
    sid       = "CreateAirflowToken"
    effect    = "Allow"
    actions   = ["airflow:CreateCliToken"]
    resources = [aws_mwaa_environment.main.arn]
  }
}

module "create_airflow_token_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.59.0"

  name_prefix = "create-airflow-token-"

  policy = data.aws_iam_policy_document.create_airflow_token.json

  tags = local.tags
}
