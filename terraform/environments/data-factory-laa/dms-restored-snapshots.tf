# =============================================================================
# DMS pipelines for RDS instances restored from shared snapshots (TEST ONLY)
#
# This file is the home for Postgres DMS -> S3 -> Glue pipelines that read from
# RDS instances restored from shared snapshots (see the matching restore in
# rds-*.tf). Each restored source gets its own self-contained set of resources
# below; add a new section per source as more snapshots arrive.
#
# Sources:
#   1. Access — aws_db_instance.access (restored in rds-access.tf)
#
# Conventions shared by every source in this file:
# - All resources are gated on local.is-test (test account 766696030771) and are
#   self-contained: each creates its own KMS key, S3 config bucket, Glue access
#   role, Slack webhook placeholder and the literal-named dms-vpc-role, because
#   the equivalents in dms.tf are gated on local.is-development (development
#   account) and do not exist in test.
# - Migration type is FULL LOAD ONLY. A restored snapshot is a static
#   point-in-time copy, so CDC would stream nothing — the cdc key is omitted.
# - The source endpoint connects as the DB MASTER user (credentials stored
#   alongside the restore, e.g. aws_secretsmanager_secret.access_master in
#   rds-access.tf). Using master avoids creating a dedicated dms_user role
#   inside the DB, which is not possible here — the CI pipeline runs outside the
#   VPC and the read-only developer role cannot reach the private RDS.
# - The mapping must list EXACT schema and table names. The DMS module builds
#   selection rules with rule-action "explicit", and AWS DMS rejects "%"
#   wildcards for explicit rules ("Exact schema name and table name required").
#   The Access objects were derived from the laa-data-access-api Flyway
#   migrations (schema "public"); see dms-config/access-dms-mappings.json.
# =============================================================================

# #############################################################################
# # Source 1: Access
# #############################################################################

# ---------------------------------------------------------------------------
# KMS key for the Access DMS test resources (SQS validation queue, secret)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "access_dms_kms" {
  count = local.is-test ? 1 : 0

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

resource "aws_kms_key" "access_dms" {
  count = local.is-test ? 1 : 0

  description         = "KMS key for Access Postgres DMS test resources"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.access_dms_kms[0].json

  tags = local.tags
}

resource "aws_kms_alias" "access_dms" {
  count = local.is-test ? 1 : 0

  name          = "alias/${local.application_name}-access-dms"
  target_key_id = aws_kms_key.access_dms[0].key_id
}

# ---------------------------------------------------------------------------
# S3 bucket for DMS mapping rules
# ---------------------------------------------------------------------------

#trivy:ignore:AVD-AWS-0089 No logging required for test config bucket
#checkov:skip=CKV_AWS_18:Access logging not required for test config bucket
#checkov:skip=CKV_AWS_144:Cross-region replication not required for test config bucket
#checkov:skip=CKV2_AWS_61:Lifecycle configuration not required for test config bucket
#checkov:skip=CKV2_AWS_62:Event notifications not required for test config bucket
resource "aws_s3_bucket" "access_dms_config" {
  count  = local.is-test ? 1 : 0
  bucket = "${local.application_name}-${local.environment}-access-dms-config"
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "access_dms_config" {
  count  = local.is-test ? 1 : 0
  bucket = aws_s3_bucket.access_dms_config[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "access_dms_config" {
  count  = local.is-test ? 1 : 0
  bucket = aws_s3_bucket.access_dms_config[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

#trivy:ignore:AVD-AWS-0132 Uses AES256 encryption
#checkov:skip=CKV_AWS_145:KMS encryption not required for test config bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "access_dms_config" {
  count  = local.is-test ? 1 : 0
  bucket = aws_s3_bucket.access_dms_config[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "access_dms_mappings" {
  count        = local.is-test ? 1 : 0
  bucket       = aws_s3_bucket.access_dms_config[0].id
  key          = "mappings/access-dms.json"
  content      = file("${path.module}/dms-config/access-dms-mappings.json")
  content_type = "application/json"
  tags         = local.tags
}

# ---------------------------------------------------------------------------
# Slack webhook secret (placeholder for testing)
# ---------------------------------------------------------------------------

#checkov:skip=CKV2_AWS_57: Automatic rotation not needed for test webhook
resource "aws_secretsmanager_secret" "access_dms_slack_webhook" {
  count = local.is-test ? 1 : 0
  name  = "${local.application_name}-${local.environment}/access-dms/slack-webhook"
  tags  = local.tags
}

resource "aws_secretsmanager_secret_version" "access_dms_slack_webhook" {
  count         = local.is-test ? 1 : 0
  secret_id     = aws_secretsmanager_secret.access_dms_slack_webhook[0].id
  secret_string = "https://hooks.slack.com/services/placeholder"
}

# ---------------------------------------------------------------------------
# DMS service-linked role (must be named exactly "dms-vpc-role")
# AWS DMS looks up this role by literal name when creating a replication
# subnet group. This is the test-account copy (the dms.tf one is is-development).
# ---------------------------------------------------------------------------
resource "aws_iam_role" "access_dms_vpc_role" {
  count = local.is-test ? 1 : 0
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

resource "aws_iam_role_policy_attachment" "access_dms_vpc_role" {
  count      = local.is-test ? 1 : 0
  role       = aws_iam_role.access_dms_vpc_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"

  # IAM propagation delay; DMS will reject the role until the attachment lands
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

# ---------------------------------------------------------------------------
# IAM role for metadata generator Lambda to access Glue catalog
# ---------------------------------------------------------------------------

resource "aws_iam_role" "access_dms_glue_access" {
  count = local.is-test ? 1 : 0
  name  = "${local.application_name}-access-dms-glue-access"

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

resource "aws_iam_role_policy" "access_dms_glue_access" {
  count = local.is-test ? 1 : 0
  name  = "glue-catalog-access"
  role  = aws_iam_role.access_dms_glue_access[0].id

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
# DMS Module — Access Postgres (full load only)
# ---------------------------------------------------------------------------

#trivy:ignore:AVD-AWS-0066 X-Ray tracing not currently required
module "dms_access" {
  # checkov:skip=CKV_TF_1: using pinned commit ref for testing
  # checkov:skip=CKV_TF_2: using pinned commit ref for testing
  count  = local.is-test ? 1 : 0
  source = "github.com/ministryofjustice/terraform-dms-module?ref=9a072261e161663af6f630a4982fb8dec71e0c70"

  vpc_id      = data.aws_vpc.shared.id
  environment = local.environment
  db          = "access-dms"
  tags        = local.tags

  validation_sqs_kms_key_arn = aws_kms_key.access_dms[0].arn

  write_metadata_to_glue_catalog = true
  glue_catalog_arn               = "arn:aws:glue:eu-west-2:${data.aws_caller_identity.current.account_id}:catalog"
  glue_catalog_role_arn          = aws_iam_role.access_dms_glue_access[0].arn

  dms_replication_instance = {
    replication_instance_id = "${local.application_name}-access-dms"
    # Data subnets: DMS/RDS DNS only resolves here (private subnets give NXDOMAIN)
    subnet_ids                 = data.aws_subnets.shared-data.ids
    allocated_storage          = 50
    availability_zone          = "eu-west-2a"
    engine_version             = "3.5.4"
    kms_key_arn                = aws_kms_key.access_dms[0].arn
    multi_az                   = false
    replication_instance_class = "dms.t3.medium"
    inbound_cidr               = data.aws_vpc.shared.cidr_block
    apply_immediately          = true
  }

  dms_source = {
    engine_name             = "postgres"
    secrets_manager_arn     = aws_secretsmanager_secret.access_master[0].arn
    secrets_manager_kms_arn = aws_kms_key.access_rds[0].arn
    database_name           = aws_db_instance.access[0].db_name
    # PluginName=test_decoding — built-in logical decoding plugin on RDS
    # sslMode=require          — RDS enforces SSL via pg_hba.conf
    extra_connection_attributes = "PluginName=test_decoding;sslMode=require;"
  }

  # Full load only — no cdc key, the restored DB is a static copy.
  replication_task_id = {
    full_load = "${local.application_name}-access-dms-full-load"
  }

  dms_mapping_rules = {
    bucket = aws_s3_bucket.access_dms_config[0].id
    key    = aws_s3_object.access_dms_mappings[0].key
  }

  slack_webhook_secret_id = aws_secretsmanager_secret.access_dms_slack_webhook[0].id

  depends_on = [
    aws_iam_role_policy_attachment.access_dms_vpc_role,
    aws_s3_object.access_dms_mappings[0],
  ]
}
