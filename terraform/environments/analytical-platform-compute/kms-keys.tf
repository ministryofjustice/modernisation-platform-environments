# module "vpc_flow_logs_kms" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#   #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

#   source  = "terraform-aws-modules/kms/aws"
#   version = "3.1.1"

#   aliases                 = ["vpc/flow-logs"]
#   description             = "VPC flow logs KMS key"
#   enable_default_policy   = true
#   deletion_window_in_days = 7
#   key_statements = [
#     {
#       sid = "AllowCloudWatchLogs"
#       actions = [
#         "kms:Encrypt*",
#         "kms:Decrypt*",
#         "kms:ReEncrypt*",
#         "kms:GenerateDataKey*",
#         "kms:Describe*"
#       ]
#       resources = ["*"]
#       effect    = "Allow"
#       principals = [
#         {
#           type        = "Service"
#           identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
#         }
#       ]
#       conditions = [
#         {
#           test     = "ArnEquals"
#           variable = "kms:EncryptionContext:aws:logs:arn"
#           values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${local.vpc_flow_log_cloudwatch_log_group_name_prefix}*"]
#         }
#       ]
#     }
#   ]

#   tags = local.tags
# }

module "mojap_compute_logs_s3_kms_eu_west_2" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/mojap-compute-logs-eu-west-2"]
  description           = "mojap-compute-logs eu-west-2 S3 KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags

  key_statements = [
    {
      sid    = "AllowS3Logging"
      effect = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["logging.s3.amazonaws.com"]
        }
      ]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["logging.s3.amazonaws.com"]
        }
      ]
    }
  ]
}

module "mojap_compute_logs_s3_kms_eu_west_1" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  providers = {
    aws = aws.analytical-platform-compute-eu-west-1
  }

  aliases               = ["s3/mojap-compute-logs-eu-west-1"]
  description           = "mojap-compute-logs eu-west-1 S3 KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7

  tags = local.tags

  key_statements = [
    {
      sid    = "AllowS3Logging"
      effect = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:GenerateDataKeyWithoutPlaintext",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["logging.s3.amazonaws.com"]
        }
      ]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["logging.s3.amazonaws.com"]
        }
      ]
    }
  ]
}
