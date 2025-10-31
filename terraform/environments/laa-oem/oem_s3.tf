resource "aws_s3_bucket" "laa_oem_shared" {
  bucket = "${local.application_name}-${local.environment}-shared"
}