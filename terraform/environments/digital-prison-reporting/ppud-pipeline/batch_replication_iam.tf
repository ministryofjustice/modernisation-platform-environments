
data "aws_iam_policy_document" "batch_replication_destination" {

  statement {
    sid    = "AllowReplicationFromSourceRole"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [local.source_bucket_role_arn]
    }

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]

    resources = [
      "${module.rds_export.parquet_exports_bucket_arn}/*"
    ]
  }

  statement {
    sid    = "AllowReplicationBucketPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [local.source_bucket_role_arn]
    }

    actions = [
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]

    resources = [
      module.rds_export.parquet_exports_bucket_arn
    ]
  }
}

resource "aws_s3_bucket_policy" "batch_replication_destination" {

  bucket = module.rds_export.parquet_exports_bucket_id
  policy = data.aws_iam_policy_document.batch_replication_destination.json
}