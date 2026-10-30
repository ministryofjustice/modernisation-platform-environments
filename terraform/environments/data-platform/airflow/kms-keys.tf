module "mwaa_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.2.2"

  aliases               = ["mwaa/default"]
  enable_default_policy = true
  # TEMPORARY (Airflow 3 durability test): "[" changed to "concat([" - revert to "[" after the test
  key_statements = concat([
    {
      # https://docs.aws.amazon.com/mwaa/latest/userguide/custom-keys-certs.html#custom-keys-certs-grant-policies-attach
      sid    = "AllowCloudWatchLogs"
      effect = "Allow"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]
      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
        }
      ]
      condition = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values   = ["arn:aws:logs:${data.aws_region.current.region}:*:*"]
        }
      ]
    }
    ],
    # >>> TEMPORARY (Airflow 3 durability test): START
    length(local.mwaa_bucket_workflow_all_role_arns) > 0 ? [
      {
        sid    = "AllowAirflowWorkflowRolesViaS3"
        effect = "Allow"
        actions = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        resources = ["*"]
        principals = [
          {
            type        = "AWS"
            identifiers = local.mwaa_bucket_workflow_all_role_arns
          }
        ]
        condition = [
          {
            test     = "StringEquals"
            variable = "kms:ViaService"
            values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
          }
        ]
      }
    ] : []
    # <<< TEMPORARY (Airflow 3 durability test): END
  )

  deletion_window_in_days = 7

  tags = local.tags
}
