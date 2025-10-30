module "vpc_flow_logs_kms" {
  count = local.environment == "production" ? 1 : 0

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  description = "VPC Flow Logs KMS key"

  key_administrators = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]

  key_service_roles_for_autoscaling = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
  ]

  key_statements = [
    {
      sid = "Allow CloudWatch Logs"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:CreateGrant",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      principals = [
        {
          type = "Service"
          identifiers = [
            "logs.${data.aws_region.current.name}.amazonaws.com"
          ]
        }
      ]
      conditions = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values = [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.vpc_flow_log_cloudwatch_log_group_name_prefix}${local.vpc_flow_log_cloudwatch_log_group_name_suffix}"
          ]
        }
      ]
    }
  ]

  aliases = ["vpc-flow-logs-secure-browser"]

  tags = local.tags
}
