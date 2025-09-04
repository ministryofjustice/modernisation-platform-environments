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
        },
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/lakeformation.amazonaws.com/AWSServiceRoleForLakeFormationDataAccess"]
        }
      ]
    }
  ]

  deletion_window_in_days = 7
}
