# RETIRED
# data "aws_iam_policy_document" "glue_crawler" {
#   statement {
#     # This statement is a workaround for a bug I found when using a KMS key in 'aws_glue_security_configuration.main.encryption_configuration.cloudwatch_encryption'
#     sid       = "AllowCloudWatchLogsActions"
#     effect    = "Allow"
#     actions   = ["logs:AssociateKmsKey"]
#     resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/*"]
#   }
#   statement {
#     sid    = "AllowGlueKMSActions"
#     effect = "Allow"
#     actions = [
#       "kms:Decrypt",
#       "kms:Encrypt",
#       "kms:GenerateDataKey"
#     ]
#     resources = [
#       module.glue_catalog_kms_key.key_arn,
#       module.glue_connections_kms_key.key_arn, # TODO (@jacobwoffenden): Is this needed in the Glue crawler?
#       module.glue_crawler_logs_kms_key.key_arn
#     ]
#   }
#   statement {
#     sid       = "AllowS3KMSActions"
#     effect    = "Allow"
#     actions   = ["kms:Decrypt"]
#     resources = [module.s3_mojap_next_poc_data_kms_key.key_arn]
#   }
#   statement {
#     sid       = "AllowS3Actions"
#     effect    = "Allow"
#     actions   = ["s3:GetObject"]
#     resources = ["${module.mojap_next_poc_data_s3_bucket.s3_bucket_arn}/*"]
#   }
# }

# RETIRED
# module "glue_crawler_iam_policy" {
#   #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
#   #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

#   source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
#   version = "5.59.0"

#   name_prefix = "glue-crawler"
#   policy      = data.aws_iam_policy_document.glue_crawler.json
# }
