# =============================================================================
# DMS Oracle Test - Development only
# Deploys terraform-dms-module against the throwaway Oracle RDS instance

# =============================================================================

# ---------------------------------------------------------------------------
# Data sources for existing resources 
# ---------------------------------------------------------------------------

data "aws_secretsmanager_secret" "dms_oracle_credentials" {
  count = local.is-development ? 1 : 0
  name  = "laa-df-dev/oracle-dms-test/dms-user"
}

data "aws_kms_key" "oracle_dms" {
  count  = local.is-development ? 1 : 0
  key_id = "alias/laa-df-dev-dms-test"
}

# ---------------------------------------------------------------------------
# S3 bucket for DMS mapping rules
# ---------------------------------------------------------------------------

#trivy:ignore:AVD-AWS-0089 No logging required for test config bucket
#checkov:skip=CKV_AWS_18:Access logging not required for test config bucket
#checkov:skip=CKV_AWS_144:Cross-region replication not required for test config bucket
#checkov:skip=CKV2_AWS_61:Lifecycle configuration not required for test config bucket
#checkov:skip=CKV2_AWS_62:Event notifications not required for test config bucket
resource "aws_s3_bucket" "dms_config" {
  count  = local.is-development ? 1 : 0
  bucket = "${local.application_name}-${local.environment}-dms-config"
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "dms_config" {
  count  = local.is-development ? 1 : 0
  bucket = aws_s3_bucket.dms_config[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "dms_config" {
  count  = local.is-development ? 1 : 0
  bucket = aws_s3_bucket.dms_config[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

#trivy:ignore:AVD-AWS-0132 Uses AES256 encryption
#checkov:skip=CKV_AWS_145:KMS encryption not required for test config bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "dms_config" {
  count  = local.is-development ? 1 : 0
  bucket = aws_s3_bucket.dms_config[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "oracle_dms_mappings" {
  count        = local.is-development ? 1 : 0
  bucket       = aws_s3_bucket.dms_config[0].id
  key          = "mappings/oracle-dms-test.json"
  content      = file("${path.module}/dms-config/oracle-dms-test-mappings.json")
  content_type = "application/json"
  tags         = local.tags
}

# ---------------------------------------------------------------------------
# Slack webhook secret (placeholder for testing)
# ---------------------------------------------------------------------------

#checkov:skip=CKV2_AWS_57: Automatic rotation not needed for test webhook
resource "aws_secretsmanager_secret" "dms_slack_webhook" {
  count = local.is-development ? 1 : 0
  name  = "${local.application_name}-${local.environment}/dms/slack-webhook"
  tags  = local.tags
}

resource "aws_secretsmanager_secret_version" "dms_slack_webhook" {
  count         = local.is-development ? 1 : 0
  secret_id     = aws_secretsmanager_secret.dms_slack_webhook[0].id
  secret_string = "https://hooks.slack.com/services/placeholder"
}

# ---------------------------------------------------------------------------
# DMS Module
# ---------------------------------------------------------------------------

# IAM role for metadata generator Lambda to access Glue catalog
resource "aws_iam_role" "dms_glue_access" {
  count = local.is-development ? 1 : 0
  name  = "${local.application_name}-oracle-dms-test-glue-access"

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

resource "aws_iam_role_policy" "dms_glue_access" {
  count = local.is-development ? 1 : 0
  name  = "glue-catalog-access"
  role  = aws_iam_role.dms_glue_access[0].id

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

#trivy:ignore:AVD-AWS-0066 X-Ray tracing not currently required
module "dms_oracle" {
  # checkov:skip=CKV_TF_1: using branch ref for testing
  # checkov:skip=CKV_TF_2: using branch ref for testing
  count  = local.is-development ? 1 : 0
  source = "github.com/ministryofjustice/terraform-dms-module?ref=baf3cab"

  vpc_id      = data.aws_vpc.shared.id
  environment = local.environment
  db          = "oracle-dms-test"
  tags        = local.tags

  write_metadata_to_glue_catalog = true
  glue_catalog_arn                = "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:catalog"
  glue_catalog_role_arn           = aws_iam_role.dms_glue_access[0].arn

  dms_replication_instance = {
    replication_instance_id    = "${local.application_name}-oracle-dms-test"
    subnet_ids                 = data.aws_subnets.shared-private.ids
    allocated_storage          = 50
    availability_zone          = "eu-west-2a"
    engine_version             = "3.5.4"
    kms_key_arn                = data.aws_kms_key.oracle_dms[0].arn
    multi_az                   = false
    replication_instance_class = "dms.t3.medium"
    inbound_cidr               = data.aws_vpc.shared.cidr_block
    apply_immediately          = true
  }

  dms_source = {
    engine_name                 = "oracle"
    secrets_manager_arn         = data.aws_secretsmanager_secret.dms_oracle_credentials[0].arn
    secrets_manager_kms_arn     = data.aws_kms_key.oracle_dms[0].arn
    sid                         = "DMSTEST"
    extra_connection_attributes = "addSupplementalLogging=N;useBfile=Y;useLogminerReader=N;"
  }

  replication_task_id = {
    full_load = "${local.application_name}-oracle-dms-test-full-load"
  }

  dms_mapping_rules = {
    bucket = aws_s3_bucket.dms_config[0].id
    key    = aws_s3_object.oracle_dms_mappings[0].key
  }

  slack_webhook_secret_id = aws_secretsmanager_secret.dms_slack_webhook[0].id
}
