# module "glue_catalog_kms_key" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#   #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

#   source  = "terraform-aws-modules/kms/aws"
#   version = "4.0.0"

#   aliases               = ["glue/catalog"]
#   enable_default_policy = true

#   deletion_window_in_days = 7
# }

# module "glue_connections_kms_key" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#   #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

#   source  = "terraform-aws-modules/kms/aws"
#   version = "4.0.0"

#   aliases               = ["glue/connections"]
#   enable_default_policy = true

#   deletion_window_in_days = 7
# }

# module "glue_crawler_logs_kms_key" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#   #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

#   source  = "terraform-aws-modules/kms/aws"
#   version = "4.0.0"

#   aliases               = ["glue/crawler/logs"]
#   enable_default_policy = true
#   key_statements = [
#     {
#       sid    = "AllowCloudWatchLogs"
#       effect = "Allow"
#       actions = [
#         "kms:Decrypt*",
#         "kms:Describe*",
#         "kms:Encrypt*",
#         "kms:GenerateDataKey*",
#         "kms:ReEncrypt*"
#       ]
#       resources = ["*"]
#       principals = [
#         {
#           type        = "Service"
#           identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
#         }
#       ]
#       conditions = [
#         {
#           test     = "ArnEquals"
#           variable = "kms:EncryptionContext:aws:logs:arn"
#           values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*"]
#         }
#       ]
#     }
#   ]

#   deletion_window_in_days = 7
# }

module "s3_mojap_next_poc_athena_query_kms_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases               = ["s3/${local.athena_query_bucket_name}"]
  enable_default_policy = true

  deletion_window_in_days = 7
}

module "s3_mojap_next_poc_data_kms_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases               = ["s3/${local.datastore_bucket_name}"]
  enable_default_policy = true
  key_statements = [
    {
      sid    = "AllowAnalyticalPlatformNextPoCHub"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${local.hub_account_id}:root"]
        }
      ]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values = [
            "s3.${data.aws_region.current.region}.amazonaws.com",
            "lakeformation.${data.aws_region.current.region}.amazonaws.com"
          ]
        }
      ]
    },
    {
      sid    = "AllowLakeFormationService"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["lakeformation.amazonaws.com"]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}
