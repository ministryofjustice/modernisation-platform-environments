output "upload_bucket" {
  description = "Upload bucket details for API-driven managed file transfer ingestion"

  value = {
    arn         = module.s3_bucket["unscanned"].s3_bucket_arn
    id          = module.s3_bucket["unscanned"].s3_bucket_id
    kms_key_arn = module.kms_s3_bucket["unscanned"].key_arn
  }
}
