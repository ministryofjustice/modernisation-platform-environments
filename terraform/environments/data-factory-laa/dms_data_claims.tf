resource "aws_secretsmanager_secret" "data_claims_database" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  count      = local.is-test ? 1 : 0
  name       = "data-claims-secret"
  kms_key_id = aws_kms_key.data_lake_kms_key.arn
}

module "data_claims_mapping_bucket" {
  count               = local.is-test ? 1 : 0
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"
  bucket_prefix       = "data-claims-mapping"
  bucket_namespace    = "account-regional"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  sse_algorithm       = "aws:kms"
  custom_kms_key      = aws_kms_key.data_lake_kms_key.arn

  providers = {
    aws.bucket-replication = aws
  }

  tags = local.tags
}

# Upload the table mapping file to S3
resource "aws_s3_object" "data_claims_mapping_file" {
  count        = local.is-test ? 1 : 0
  bucket       = module.data_claims_mapping_bucket[0].bucket.id
  key          = "table_mappings.json"
  source       = "${path.module}/table_mappings/data_claims_mappings.json"
  content_type = "application/json"
  kms_key_id   = aws_kms_key.data_lake_kms_key.arn

  source_hash = filemd5(
    "${path.module}/table_mappings/data_claims_mappings.json"
  )
}

# TODO: Move to shared file
resource "aws_secretsmanager_secret" "slack_webhook_dms" {
  #checkov:skip=CKV2_AWS_57: Automatic rotation not needed for test webhook
  name       = "dms/slack-webhook"
  kms_key_id = aws_kms_key.data_lake_kms_key.arn
  tags       = local.tags
}

resource "aws_secretsmanager_secret_version" "slack_webhook_dms" {
  secret_id     = aws_secretsmanager_secret.slack_webhook_dms.id
  secret_string = "https://hooks.slack.com/services/placeholder"
}

resource "aws_iam_role" "glue_access_dms" {
  name = "dms-glue-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "glue_access_dms" {
  name = "glue-catalog-access"
  role = aws_iam_role.glue_access_dms.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:CreateDatabase",
          "glue:GetTable",
          "glue:CreateTable",
          "glue:UpdateTable"
        ]
        Resource = [
          "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:database/*",
          "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:table/*/*"
        ]
      }
    ]
  })
}


module "data_claims_dms" {
  count                    = local.is-test ? 1 : 0
  source                   = "github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/database-migration-service?ref=5af822545b8c47096e979c5c07e2fc1bc2579eb1"
  vpc_id                   = data.aws_vpc.shared.id
  environment              = local.environment
  manage_dms_service_roles = false

  db                         = "data-claims"
  slack_webhook_secret_id    = aws_secretsmanager_secret.slack_webhook_dms.id
  output_key_prefix          = "data_claims"
  output_bucket              = module.data_lake_buckets["raw"].bucket.id
  output_bucket_kms_key_arn  = aws_kms_key.data_lake_kms_key.arn
  validation_sqs_kms_key_arn = aws_kms_key.data_lake_kms_key.arn

  dms_replication_instance = {
    replication_instance_id = "data-claims"
    subnet_ids              = data.aws_subnets.shared-private.ids
    allocated_storage       = 100
    availability_zone       = data.aws_availability_zones.available.names[0]
    # TODO: Fix module to allow 3.6.1
    engine_version             = "3.5.4"
    kms_key_arn                = aws_kms_key.data_lake_kms_key.arn
    multi_az                   = false
    replication_instance_class = "dms.r6i.2xlarge"
    inbound_cidr               = "192.0.2.0/32" # TODO: Not needed
    apply_immediately          = true
  }

  dms_source = {
    engine_name             = "postgres"
    secrets_manager_arn     = aws_secretsmanager_secret.data_claims_database[0].arn
    secrets_manager_kms_arn = aws_kms_key.data_lake_kms_key.arn
    database_name           = "db36c8528316c5b918"
    ssl_mode                = "require"
  }

  replication_task_id = {
    full_load = "data-claims-full-load"
    cdc       = "data-claims-cdc"
  }

  dms_mapping_rules = {
    bucket = module.data_claims_mapping_bucket[0].bucket.id
    key    = "table_mappings.json"
  }


  write_metadata_to_glue_catalog = true
  glue_catalog_arn               = "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:catalog"
  glue_catalog_role_arn          = aws_iam_role.glue_access_dms.arn

  tags = local.tags

  depends_on = [
    aws_s3_object.data_claims_mapping_file
  ]
}
