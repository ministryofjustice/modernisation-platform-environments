resource "aws_s3_bucket" "dms_dv_parquet_s3_bucket" {
  bucket_prefix = "dms-data-validation-"

  tags = merge(
    local.tags,
    {
      Resource_Type = "S3 Bucket for Athena Parquet Tables",
    }
  )
}

resource "aws_s3_bucket_public_access_block" "dms_dv_parquet_s3_bucket" {
  bucket                  = aws_s3_bucket.dms_dv_parquet_s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dms_dv_parquet_s3_bucket" {
  bucket = aws_s3_bucket.dms_dv_parquet_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "dms_dv_parquet_s3_bucket" {
  bucket = aws_s3_bucket.dms_dv_parquet_s3_bucket.id
  policy = data.aws_iam_policy_document.dms_dv_parquet_s3_bucket.json
}

# -------------------------------------------------------------------

resource "aws_s3_bucket" "dms_dv_glue_job_s3_bucket" {
  bucket_prefix = "glue-jobs-py-scripts-"
}

resource "aws_s3_object" "dms_dv_glue_job_s3_object" {
  bucket = aws_s3_bucket.dms_dv_glue_job_s3_bucket.id
  key    = "dms_dv_rds_and_s3_csv.py"
  source = "glue-job/dms_dv_rds_and_s3_csv.py"
  etag   = filemd5("glue-job/dms_dv_rds_and_s3_csv.py")
}

# -------------------------------------------------------------------

