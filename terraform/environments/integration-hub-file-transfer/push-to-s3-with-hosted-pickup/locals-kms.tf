locals {
  clean_kms_key_alias   = "alias/s3/clean"
  secrets_kms_key_alias = "alias/secrets/${local.application_name}-${local.environment}"
  logs_kms_key_alias    = "alias/logs/${local.application_name}-${local.environment}"
}