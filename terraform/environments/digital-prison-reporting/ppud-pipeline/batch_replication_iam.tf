
data "aws_iam_policy_document" "batch_replication_destination" {

  count = local.is-development ? 1 : 0

  statement {
    sid    = "AllowBatchCopyToDestination"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [local.source_bucket_role_arn]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]

    resources = [
      "${module.ppud_rds_export[0].parquet_exports_bucket_arn}/*"
    ]
  }
}
