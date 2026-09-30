resource "aws_s3_bucket" "laa_oem_shared" {
  bucket = "${local.application_name}-${local.environment}-shared"
}

resource "aws_s3_bucket_logging" "laa_oem_shared" {
  bucket = aws_s3_bucket.laa_oem_shared.id

  target_bucket = module.laa_oem_logging.bucket.id
  target_prefix = "s3access/${local.application_name}-${local.environment}-shared"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}