module "vpc_flow_logs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases                 = ["vpc/flow-logs"]
  description             = "VPC flow logs KMS key"
  enable_default_policy   = true
  deletion_window_in_days = 7
  key_statements = [
    {
      sid = "AllowCloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
        }
      ]
      conditions = [
        {
          test     = "ArnEquals"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.vpc_flow_log_cloudwatch_log_group_name_prefix}*"]
        }
      ]
    }
  ]

  tags = local.tags
}

module "managed_prometheus_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases                 = ["amp/default"]
  description             = "AMP KMS key"
  enable_default_policy   = true
  deletion_window_in_days = 7
  key_statements = [
    {
      sid = "AllowAmazonManagedPrometheus"
      actions = [
        "kms:DescribeKey",
        "kms:CreateGrant",
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["aps.${data.aws_region.current.name}.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "kms:CallerAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  ]

  tags = local.tags
}

module "managed_prometheus_logs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases                 = ["amp/logs"]
  description             = "AMP logs KMS key"
  enable_default_policy   = true
  deletion_window_in_days = 7
  key_statements = [
    {
      sid = "AllowCloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
        }
      ]
      conditions = [
        {
          test     = "ArnEquals"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.amp_cloudwatch_log_group_name}*"]
        }
      ]
    }
  ]

  tags = local.tags
}

module "eks_cluster_logs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases                 = ["eks/cluster-logs"]
  description             = "EKS cluster logs KMS key"
  enable_default_policy   = true
  deletion_window_in_days = 7
  key_statements = [
    {
      sid = "AllowCloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
        }
      ]
      conditions = [
        {
          test     = "ArnEquals"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/*"]
        }
      ]
    }
  ]

  tags = local.tags
}

module "eks_ebs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases                 = ["eks/ebs"]
  description             = "EKS EBS KMS key"
  enable_default_policy   = true
  deletion_window_in_days = 7
  key_service_roles_for_autoscaling = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    module.eks.cluster_iam_role_arn
  ]
  key_statements = [
    {
      sid = "AllowEC2"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:CreateGrant",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["ec2.${data.aws_region.current.name}.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "kms:CallerAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  ]

  tags = local.tags
}

moved {
  from = module.ebs_kms
  to   = module.eks_ebs_kms
}

module "mlflow_auth_rds_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["rds/mlflow-auth"]
  description           = "MLflow Auth RDS KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "mlflow_rds_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["rds/mlflow"]
  description           = "MLflow RDS KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "mlflow_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/mlflow"]
  description           = "MLflow S3 KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "common_secrets_manager_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["secretsmanager/common"]
  description           = "Common Secrets Manager KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "karpenter_sqs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["sqs/karpenter"]
  description           = "Karpenter SQS KMS key"
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowAmazonEventBridge"
      actions = [
        "kms:GenerateDataKey",
        "kms:Decrypt"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["events.amazonaws.com"]
        }
      ]
    }
  ]

  deletion_window_in_days = 7

  tags = local.tags
}

module "ui_rds_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["rds/ui"]
  description           = "UI RDS KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}

module "actions_runner_cache_efs_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  count = terraform.workspace == "analytical-platform-compute-production" ? 1 : 0

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["efs/actions-runner-cache"]
  description           = "Actions Runner Cache EFS KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags
}
