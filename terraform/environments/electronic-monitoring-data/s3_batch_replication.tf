locals {
  replication_prefixes = [
    "g4s_tasking_second_dump/dbo/",
  ]
}


resource "aws_iam_role" "replication_role" {
  count = local.is-development || local.is-production ? 1 : 0
  name = "s3-batch-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["s3.amazonaws.com", "batchoperations.s3.amazonaws.com"]
        }
      }
    ]
  })
}

resource "aws_iam_policy" "replication_policy" {
  count = local.is-development || local.is-production ? 1 : 0
  name = "s3-replication-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket", "s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
        Effect   = "Allow"
        Resource = ["arn:aws:s3:::emds-prod-dms-rds-to-parquet-*", "arn:aws:s3:::emds-prod-dms-rds-to-parquet-*/*"]
      },
      {
        Action   = ["s3:ReplicateObject", "s3:ReplicateTags", "s3:GetObjectVersionTagging"]
        Effect   = "Allow"
        Resource = ["arn:aws:s3:::emds-preprod-dms-rds-to-parquet-*/*"]
      },
      {
        Action   = ["kms:Decrypt"]
        Effect   = "Allow"
        Resource = ["arn:aws:kms:eu-west-2:${local.environment_management.account_ids["electronic-monitoring-data-production"]}:key/20481f03-8204-4dec-9bd6-3719aac0149a"]
      },
      {
        Action   = ["kms:Encrypt"]
        Effect   = "Allow"
        Resource = ["arn:aws:kms:eu-west-2:${local.environment_management.account_ids["electronic-monitoring-data-preproduction"]}:key/6addee2b-54c4-43d2-ab8d-fab1f9b78411"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication_attach" {
  count = local.is-development || local.is-production ? 1 : 0
  role       = aws_iam_role.replication_role[0].name
  policy_arn = aws_iam_policy.replication_policy[0].arn
}

resource "aws_s3_bucket_replication_configuration" "prod_to_preprod_replication" {
  count = local.is-development || local.is-production ? 1 : 0

  role   = aws_iam_role.replication_role[0].arn
  bucket = module.s3-dms-target-store-bucket.bucket.arn


  dynamic "rule" {
    for_each = local.replication_prefixes
    content { 
      id     = "historic-backfill-rule"
      status = "Enabled"

      source_selection_criteria {
        sse_kms_encrypted_objects {
          status = "Enabled"
        }
      }

      filter {
        prefix = rule.value
      }

      destination {
        bucket        = "arn:aws:s3:::emds-preprod-dms-rds-to-parquet-*"
        storage_class = "STANDARD"

        encryption_configuration {
          replica_kms_key_id = "arn:aws:kms:eu-west-2:${local.environment_management.account_ids["electronic-monitoring-data-preproduction"]}:key/6addee2b-54c4-43d2-ab8d-fab1f9b78411"
        }
      }

      existing_object_replication {
        status = "Enabled"
      }
    }
  }
}