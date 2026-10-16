module "airflow_oidc" {
  source = "./modules/airflow-oidc"
}

module "cadet_role" {
  source = "./modules/cadet-role"

  identity_provider_arn = module.airflow_oidc.oidc_arn
}

# TODO: Use KMS key for encryption.
module "s3-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=0294b1a1303028f91707fdc67f1e4bba63d34ea6"

  manage_log_bucket_policy = false
  log_buckets              = local.access_log_destination

  bucket_prefix      = "laa-data-factory-raw"
  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  # Default/recommended encryption mode
  #sse_algorithm  = "aws:kms"
  #custom_kms_key = "arn:aws:kms:eu-west-2:123456789012:key/your-key-id"

  sse_algorithm = "AES256"

  tags = local.tags
}

module "airflow_data_ingestion_role" {
  source = "./modules/airflow-data-ingestion-role"

  identity_provider_arn = module.airflow_oidc.oidc_arn
  data_buckets          = [module.s3-bucket.bucket.id]
}
