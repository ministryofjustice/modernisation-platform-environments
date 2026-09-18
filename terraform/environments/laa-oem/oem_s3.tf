resource "aws_s3_bucket" "laa_oem_shared" {
  bucket = "${local.application_name}-${local.environment}-shared"
}

resource "aws_s3_bucket_logging" "laa_oem_shared" {
  # Bucket is managed in a separate Terraform state. We can still apply logging by
  # referencing the bucket name directly instead of a resource reference.
  bucket = aws_s3_bucket.laa_oem_shared.id

  target_bucket = module.laa_oem_logging.bucket.id
  target_prefix = "log/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}