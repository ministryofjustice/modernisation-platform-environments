resource "aws_s3_bucket" "athena_parquet_s3_bucket" {
  bucket_prefix = "dms-data-validation-"

  tags = merge(
    local.tags,
    {
      Resource_Type = "S3 Bucket for Athena Parquet Tables",
    }
  )
}

resource "aws_s3_bucket_public_access_block" "athena_iceberg_s3_bucket" {
  bucket                  = aws_s3_bucket.athena_parquet_s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "athena_iceberg_s3_bucket" {
  bucket = aws_s3_bucket.athena_parquet_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_glue_catalog_database" "dms_dv_glue_catalog_db" {
  name = "dms_data_validation"
  # create_table_default_permission {
  #   permissions = ["SELECT"]

  #   principal {
  #     data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
  #   }
  # }
}

#  resource "aws_athena_database" "dms_dv_athena_database" {
#    name   = "dms_data_validation"
#    bucket = aws_s3_bucket.athena_parquet_s3_bucket.id

# #    encryption_configuration {
# #       encryption_option = "SSE_KMS"
# #       kms_key_arn       = aws_kms_key.example.arn
# #   }
#  }

#  resource "aws_athena_workgroup" "glue_parquet_athena_workgroup" {
#    name = "glue_parquet"

#    configuration {
#      enforce_workgroup_configuration    = true
#      publish_cloudwatch_metrics_enabled = true

#      result_configuration {
#        output_location = "s3://${aws_s3_bucket.athena_iceberg_s3_bucket.bucket}/athena_workgroup/"

#     #    encryption_configuration {
#     #      encryption_option = "SSE_KMS"
#     #      kms_key_arn       = aws_kms_key.example.arn
#     #    }
#      }
#    }
#  }