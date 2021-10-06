# Get secret by name for environment management
data "aws_secretsmanager_secret" "environment_management" {
  provider = aws.modernisation-platform
  name     = "environment_management"
}

# Get latest secret value with ID from above. This secret stores account IDs for the Modernisation Platform sub-accounts
data "aws_secretsmanager_secret_version" "environment_management" {
  provider  = aws.modernisation-platform
  secret_id = data.aws_secretsmanager_secret.environment_management.id
}

## == DATABASE CONNECTIONS ==

# Get secret by name for database password
# data "aws_secretsmanager_secret" "database_password" {
#   name = "performance_hub_db"
# }

# data "aws_secretsmanager_secret_version" "database_password" {
#   secret_id = data.aws_secretsmanager_secret.database_password.arn
# }

# Get secret by name for database connection string
data "aws_secretsmanager_secret" "mojhub_cnnstr" {
  name = "mojhub_cnnstr"
}

data "aws_secretsmanager_secret_version" "mojhub_cnnstr" {
  secret_id = data.aws_secretsmanager_secret.mojhub_cnnstr.arn
}

# Get secret by name for membership database connection string
data "aws_secretsmanager_secret" "mojhub_membership" {
  name = "mojhub_membership"
}

data "aws_secretsmanager_secret_version" "mojhub_membership" {
  secret_id = data.aws_secretsmanager_secret.mojhub_membership.arn
}

## == API KEYS ==

# Secret by name for GOV.UK Notify API key
data "aws_secretsmanager_secret" "govuk_notify_api_key" {
  name = "govuk_notify_api_key"
}

data "aws_secretsmanager_secret_version" "govuk_notify_api_key" {
  secret_id = data.aws_secretsmanager_secret.govuk_notify_api_key.arn
}

# Secret by name for OS Vector Tile API key
data "aws_secretsmanager_secret" "os_vts_api_key" {
  name = "os_vts_api_key"
}

data "aws_secretsmanager_secret_version" "os_vts_api_key" {
  secret_id = data.aws_secretsmanager_secret.os_vts_api_key.arn
}


## == PERSISTENT STORAGE (S3) ==

# Secret by name for the persistent storage bucket name (defined as ${aws_s3_bucket.upload_files.id})
# data "aws_secretsmanager_secret" "hub_storage_bucket" {
#   name = "hub_storage_bucket"
# }

# data "aws_secretsmanager_secret_version" "hub_storage_bucket" {
#   secret_id = data.aws_secretsmanager_secret.hub_storage_bucket.arn
# }

# Secret by name for the persistent storage bucket access key ID
data "aws_secretsmanager_secret" "hub_storage_access_key_id" {
  name = "hub_storage_access_key_id"
}

data "aws_secretsmanager_secret_version" "hub_storage_access_key_id" {
  secret_id = data.aws_secretsmanager_secret.hub_storage_access_key_id.arn
}

# Secret by name for the persistent storage bucket secret access key
data "aws_secretsmanager_secret" "hub_storage_secret_access_key" {
  name = "hub_storage_secret_access_key"
}

data "aws_secretsmanager_secret_version" "hub_storage_secret_access_key" {
  secret_id = data.aws_secretsmanager_secret.hub_storage_secret_access_key.arn
}

## == ANALYTICAL PLATFORM (S3) ==

# Secret by name for AP import bucket credentials
data "aws_secretsmanager_secret" "ap_import_access_key_id" {
  name = "ap_import_access_key_id"
}

data "aws_secretsmanager_secret_version" "ap_import_access_key_id" {
  secret_id = data.aws_secretsmanager_secret.ap_import_access_key_id.arn
}

data "aws_secretsmanager_secret" "ap_import_secret_access_key" {
  name = "ap_import_secret_access_key"
}

data "aws_secretsmanager_secret_version" "ap_import_secret_access_key" {
  secret_id = data.aws_secretsmanager_secret.ap_import_secret_access_key.arn
}

# Secret by name for AP export bucket credentials
data "aws_secretsmanager_secret" "ap_export_access_key_id" {
  name = "ap_export_access_key_id"
}

data "aws_secretsmanager_secret_version" "ap_export_access_key_id" {
  secret_id = data.aws_secretsmanager_secret.ap_export_access_key_id.arn
}

data "aws_secretsmanager_secret" "ap_export_secret_access_key" {
  name = "ap_export_secret_access_key"
}

data "aws_secretsmanager_secret_version" "ap_export_secret_access_key" {
  secret_id = data.aws_secretsmanager_secret.ap_export_secret_access_key.arn
}

## == BOOK A SECURE MOVE ACCESS KEYS (S3) ==
data "aws_secretsmanager_secret" "pecs_basm_prod_access_key_id" {
  name = "pecs_basm_prod_access_key_id"
}

data "aws_secretsmanager_secret_version" "pecs_basm_prod_access_key_id" {
  secret_id = data.aws_secretsmanager_secret.pecs_basm_prod_access_key_id.arn
}

data "aws_secretsmanager_secret" "pecs_basm_prod_secret_access_key" {
  name = "pecs_basm_prod_secret_access_key"
}

data "aws_secretsmanager_secret_version" "pecs_basm_prod_secret_access_key" {
  secret_id = data.aws_secretsmanager_secret.pecs_basm_prod_secret_access_key.arn
}