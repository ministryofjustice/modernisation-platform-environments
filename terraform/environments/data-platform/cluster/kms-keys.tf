module "eks_logs_kms_key" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  aliases               = ["logs/eks/${local.eks_cluster_name}"]
  enable_default_policy = true

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
          identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
        }
      ]
      condition = [
        {
          test     = "ArnEquals"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values = [
            "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.eks_cluster_logs_log_group_name}*",
            "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.eks_application_logs_log_group_name}*"
          ]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}

module "eks_ebs_kms_key" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=407e3db34a65b384c20ef718f55d9ceacb97a846" # v4.2.0

  aliases               = ["eks/ebs"]
  enable_default_policy = true

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
      condition = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["ec2.${data.aws_region.current.region}.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "kms:CallerAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}
