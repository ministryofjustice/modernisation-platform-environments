module "sherlock_landing_bucket_mp" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  bucket_prefix      = "landing-sherlock-${local.environment}"
  bucket_namespace   = "account-regional"
  versioning_enabled = true
  force_destroy      = true

  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  # Below variable and providers configuration is only relevant if 'replication_enabled' is set to true
  # replication_region  = "eu-west-2"
  providers = {
    aws.bucket-replication = aws
  }

  # Default/recommended encryption mode
  sse_algorithm  = "aws:kms"
  custom_kms_key = module.sherlock_kms_key.key_arn

  # Optional compatibility mode for uploaders that rely on bucket default
  # SSE-KMS encryption and do not send explicit SSE-KMS request headers.
  # enforce_kms_request_headers = false

  # Optional compatibility mode for services that cannot use SSE-KMS
  # sse_algorithm = "AES256"

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "sherlock-landing-bucket-${local.environment}"
  }
}

module "sherlock_quarantine_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  bucket_prefix      = "corporate-quarantine-${local.environment}"
  bucket_namespace   = "account-regional"
  versioning_enabled = false
  force_destroy      = true

  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  # Below variable and providers configuration is only relevant if 'replication_enabled' is set to true
  # replication_region  = "eu-west-2"
  providers = {
    aws.bucket-replication = aws
  }

  # Default/recommended encryption mode
  sse_algorithm  = "aws:kms"
  custom_kms_key = module.corporate_quarantine_kms_key.key_arn

  # Optional compatibility mode for uploaders that rely on bucket default
  # SSE-KMS encryption and do not send explicit SSE-KMS request headers.
  # enforce_kms_request_headers = false

  # Optional compatibility mode for services that cannot use SSE-KMS
  # sse_algorithm = "AES256"

  tags = {
    Environment    = local.environment
    Application    = local.application
    Component      = local.component
    Infrastructure = "corporate-quarantine-bucket-${local.environment}"
  }
}