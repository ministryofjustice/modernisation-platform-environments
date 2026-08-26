
data "aws_iam_policy_document" "batch_replication_destination" {

  statement {
    sid    = "AllowBatchCopyToDestination"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [local.source_bucket_role_arn]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging"
    ]

    resources = [
      "${module.rds_export.parquet_exports_bucket_arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "batch_replication_destination" {

  bucket = module.rds_export.parquet_exports_bucket_id
  policy = data.aws_iam_policy_document.batch_replication_destination.json
}