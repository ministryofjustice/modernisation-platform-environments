# =============================================================================
# DMS Oracle Test - Development only
# Deploys terraform-dms-module against the throwaway Oracle RDS instance
#
# Oracle DMS user minimum grants for full-load + CDC:
#   GRANT CONNECT TO dms_user;
#   GRANT SELECT ANY TABLE TO dms_user;
#   GRANT SELECT_CATALOG_ROLE TO dms_user;
#   GRANT LOGMINING TO dms_user;
#
# Module quirks (ministryofjustice/terraform-dms-module):
#   - Requires hashicorp/tls provider (via Lambda sub-module) — add to versions.tf
#   - glue_catalog_arn must be set if write_metadata_to_glue_catalog = true,
#     otherwise IAM policy ARNs are malformed (empty partition)
#   - The dms-vpc-role takes ~30s to propagate after creation; first apply may
#     fail on aws_dms_replication_subnet_group — re-run resolves it
#   - Module creates dms-vpc-role with name_prefix, but AWS DMS requires the
#     literal name "dms-vpc-role" — we pre-create it with the exact name below
#   - S3 bucket notification can fail on first apply if Lambda isn't ready
#     (race condition) — re-run resolves it

# =============================================================================

# ---------------------------------------------------------------------------
# Data sources for existing resources 
# ---------------------------------------------------------------------------

data "aws_secretsmanager_secret" "dms_oracle_credentials" {
  count = local.is-development ? 1 : 0
  name  = "laa-df-dev/oracle-dms-test/dms-user"
}

data "aws_iam_policy_document" "oracle_dms_kms" {
  count = local.is-development ? 1 : 0

  statement {
    sid    = "AllowAccountRootFullAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowS3ToUseKeyForQueueNotifications"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_kms_key" "oracle_dms" {
  count = local.is-development ? 1 : 0

  description         = "KMS key for Oracle DMS test resources"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.oracle_dms_kms[0].json

  tags = local.tags
}

resource "aws_kms_alias" "oracle_dms" {
  count = local.is-development ? 1 : 0

  name          = "alias/${local.application_name}-${local.environment}-dms-test"
  target_key_id = aws_kms_key.oracle_dms[0].key_id
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
# DMS service-linked role (must be named exactly "dms-vpc-role")
# AWS DMS looks up this role by literal name when creating a replication
# subnet group. The upstream module creates one with name_prefix, which DMS
# does NOT find — so we create the literal-named role here.
# Refs: https://docs.aws.amazon.com/dms/latest/userguide/security-iam.APIRole.html
# ---------------------------------------------------------------------------
resource "aws_iam_role" "dms_vpc_role" {
  count = local.is-development ? 1 : 0
  name  = "dms-vpc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "dms.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "dms_vpc_role" {
  count      = local.is-development ? 1 : 0
  role       = aws_iam_role.dms_vpc_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"

  # IAM propagation delay; DMS will reject the role until the attachment lands
  provisioner "local-exec" {
    command = "sleep 30"
  }
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
  source = "github.com/ministryofjustice/terraform-dms-module?ref=0933e0512e10527e0ba72ba07e1e20162b6ed3be"

  vpc_id      = data.aws_vpc.shared.id
  environment = local.environment
  db          = "oracle-dms-test"
  tags        = local.tags

  manage_dms_service_roles = false

  validation_sqs_kms_key_arn = aws_kms_key.oracle_dms[0].arn

  write_metadata_to_glue_catalog = true
  glue_catalog_arn               = "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:catalog"
  glue_catalog_role_arn          = aws_iam_role.dms_glue_access[0].arn

  dms_replication_instance = {
    replication_instance_id    = "${local.application_name}-oracle-dms-test"
    subnet_ids                 = data.aws_subnets.shared-private.ids
    allocated_storage          = 50
    availability_zone          = "eu-west-2a"
    engine_version             = "3.5.4"
    kms_key_arn                = aws_kms_key.oracle_dms[0].arn
    multi_az                   = false
    replication_instance_class = "dms.t3.medium"
    inbound_cidr               = data.aws_vpc.shared.cidr_block
    apply_immediately          = true
  }

  dms_source = {
    engine_name             = "oracle"
    secrets_manager_arn     = data.aws_secretsmanager_secret.dms_oracle_credentials[0].arn
    secrets_manager_kms_arn = aws_kms_key.oracle_dms[0].arn
    sid                     = "DMSTEST"
    # Oracle extra_connection_attributes:
    #   addSupplementalLogging=N - supplemental logging is managed on the RDS instance
    #   useBfile=Y              - use BFILE for reading LOBs (faster than API)
    #   useLogminerReader=N     - use Binary Reader rather than LogMiner for CDC
    extra_connection_attributes = "addSupplementalLogging=N;useBfile=Y;useLogminerReader=N;"
  }

  replication_task_id = {
    full_load = "${local.application_name}-oracle-dms-test-full-load"
    cdc       = "${local.application_name}-oracle-dms-test-cdc"
  }

  dms_mapping_rules = {
    bucket = aws_s3_bucket.dms_config[0].id
    key    = aws_s3_object.oracle_dms_mappings[0].key
  }

  slack_webhook_secret_id = aws_secretsmanager_secret.dms_slack_webhook[0].id

  depends_on = [
    aws_iam_role_policy_attachment.dms_vpc_role,
    aws_s3_object.oracle_dms_mappings[0],
  ]
}

# =============================================================================
# DMS Postgres Test - Development only
# Deploys terraform-dms-module against the throwaway Postgres RDS instance
#
# Postgres DMS user minimum grants for full-load + CDC:
#   CREATE USER dms_user WITH PASSWORD '...';
#   GRANT CONNECT ON DATABASE dmstest TO dms_user;
#   GRANT USAGE ON SCHEMA public TO dms_user;
#   GRANT SELECT ON ALL TABLES IN SCHEMA public TO dms_user;
#   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO dms_user;
#
# For CDC (logical replication), the DMS user also needs:
#   ALTER USER dms_user WITH REPLICATION;
#
# RDS parameter group must have:
#   rds.logical_replication = 1  (enables WAL level logical)
#
# extra_connection_attributes:
#   PluginName=test_decoding  — uses the built-in test_decoding plugin on RDS;
#                               no pg_logical extension required
#
# CDC note:
#   Postgres does NOT support cdc_start_time — DMS uses WAL LSN positions.
#   The CDC task will start from the current WAL position automatically.
# =============================================================================

# ---------------------------------------------------------------------------
# Postgres DMS credentials secret
# Populate the secret value with real credentials before running terraform apply:
#   host     — RDS endpoint for the Postgres instance
#   port     — 5432
#   username — dms_user (must have CONNECT + SELECT + REPLICATION grants)
#   password — dms_user password
# ---------------------------------------------------------------------------

data "aws_secretsmanager_secret" "dms_postgres_credentials" {
  count = local.is-development ? 1 : 0
  name  = "postgres-dms-example/dms-user"
}

data "aws_kms_alias" "dms_postgres_example" {
  count = local.is-development ? 1 : 0
  name  = "alias/postgres-dms-example"
}

data "aws_iam_policy_document" "postgres_dms_kms" {
  count = local.is-development ? 1 : 0

  statement {
    sid    = "AllowAccountRootFullAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowS3ToUseKeyForQueueNotifications"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AllowEventBridgeToPublishEncryptedSns"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_kms_key" "postgres_dms" {
  count = local.is-development ? 1 : 0

  description         = "KMS key for Postgres DMS test resources"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.postgres_dms_kms[0].json

  tags = local.tags
}

resource "aws_kms_alias" "postgres_dms" {
  count = local.is-development ? 1 : 0

  name          = "alias/${local.application_name}-${local.environment}-postgres-dms-test"
  target_key_id = aws_kms_key.postgres_dms[0].key_id
}

# ---------------------------------------------------------------------------
# S3 mapping rules object (reuses existing dms_config bucket)
# ---------------------------------------------------------------------------

resource "aws_s3_object" "postgres_dms_mappings" {
  count        = local.is-development ? 1 : 0
  bucket       = aws_s3_bucket.dms_config[0].id
  key          = "mappings/postgres-dms-test.json"
  content      = file("${path.module}/dms-config/postgres-dms-test-mappings.json")
  content_type = "application/json"
  tags         = local.tags
}

# ---------------------------------------------------------------------------
# IAM role for metadata generator Lambda to access Glue catalog (Postgres)
# ---------------------------------------------------------------------------

resource "aws_iam_role" "postgres_dms_glue_access" {
  count = local.is-development ? 1 : 0
  name  = "${local.application_name}-postgres-dms-test-glue-access"

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

resource "aws_iam_role_policy" "postgres_dms_glue_access" {
  count = local.is-development ? 1 : 0
  name  = "glue-catalog-access"
  role  = aws_iam_role.postgres_dms_glue_access[0].id

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

# ---------------------------------------------------------------------------
# DMS Module — Postgres
# ---------------------------------------------------------------------------

#trivy:ignore:AVD-AWS-0066 X-Ray tracing not currently required
module "dms_postgres" {
  # checkov:skip=CKV_TF_1: using branch ref for testing
  # checkov:skip=CKV_TF_2: using branch ref for testing
  count  = local.is-development ? 1 : 0
  source = "github.com/ministryofjustice/terraform-dms-module?ref=0933e0512e10527e0ba72ba07e1e20162b6ed3be"

  vpc_id      = data.aws_vpc.shared.id
  environment = local.environment
  db          = "postgres-dms-test"
  tags        = local.tags

  manage_dms_service_roles = false

  validation_sqs_kms_key_arn = aws_kms_key.postgres_dms[0].arn

  write_metadata_to_glue_catalog = true
  glue_catalog_arn               = "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:catalog"
  glue_catalog_role_arn          = aws_iam_role.postgres_dms_glue_access[0].arn

  dms_replication_instance = {
    replication_instance_id    = "${local.application_name}-postgres-dms-test"
    subnet_ids                 = data.aws_subnets.shared-private.ids
    allocated_storage          = 50
    availability_zone          = "eu-west-2a"
    engine_version             = "3.5.4"
    kms_key_arn                = aws_kms_key.postgres_dms[0].arn
    multi_az                   = false
    replication_instance_class = "dms.t3.medium"
    inbound_cidr               = data.aws_vpc.shared.cidr_block
    apply_immediately          = true
  }

  dms_source = {
    engine_name             = "postgres"
    secrets_manager_arn     = data.aws_secretsmanager_secret.dms_postgres_credentials[0].arn
    secrets_manager_kms_arn = data.aws_kms_alias.dms_postgres_example[0].target_key_arn
    database_name           = "dmstest"
    # Postgres extra_connection_attributes:
    #   PluginName=test_decoding — built-in logical decoding plugin on RDS;
    #                              no pg_logical extension needed
    #   sslMode=require          — RDS enforces SSL via pg_hba.conf
    extra_connection_attributes = "PluginName=test_decoding;sslMode=require;"
  }

  replication_task_id = {
    full_load = "${local.application_name}-postgres-dms-test-full-load"
    cdc       = "${local.application_name}-postgres-dms-test-cdc"
  }

  dms_mapping_rules = {
    bucket = aws_s3_bucket.dms_config[0].id
    key    = aws_s3_object.postgres_dms_mappings[0].key
  }

  slack_webhook_secret_id = aws_secretsmanager_secret.dms_slack_webhook[0].id

  depends_on = [
    aws_iam_role_policy_attachment.dms_vpc_role,
    aws_s3_object.postgres_dms_mappings[0],
  ]
}
