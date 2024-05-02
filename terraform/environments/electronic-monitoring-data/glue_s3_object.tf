resource "aws_s3_bucket" "glue-jobs" {
  bucket_prefix = "glue-jobs-"
}

# --------------------------------------------------------------------------------------------------------------------------------
# create_athena_external_tables
# --------------------------------------------------------------------------------------------------------------------------------

resource "aws_s3_object" "create_athena_external_tables" {
  bucket = aws_s3_bucket.glue-jobs.id
  key    = "create_athena_external_tables.py"
  source = "glue-job/create_athena_external_tables.py"
  etag   = filemd5("glue-job/create_athena_external_tables.py")
}