data "aws_iam_policy_document" "glue-cross-account-policy" {
  statement {
    actions = [
      "glue:*",
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*"
    ]
    principals {
      identifiers = ["arn:aws:iam::${local.environment_management.account_ids[local.audit_share_map[local.environment]]}:root"]
      type        = "AWS"
    }
  }
}

resource "aws_glue_resource_policy" "this" {
  policy = data.aws_iam_policy_document.glue-cross-account-policy.json
}

resource "aws_glue_catalog_database" "this" {
  name = "glue-audit-db-${local.environment}"
}

resource "aws_glue_catalog_table" "this" {
  #   for_each = var.audit_main_account ? toset([for account in local.audit_accounts[var.env_name] : account]) : ([])
  # for_each = var.audit_main_account ? toset([for env in local.audit_envs[join("-", ["delius-core", var.account_info.mp_environment])] : env]) : toset([])
  for_each      = { for item in toset(lookup(local.audit_owner_map, local.environment, toset([]))) : item.env => item.account }
  database_name = aws_glue_catalog_database.this.name
  name          = "audit-table-${each.key}"
  description   = "table containing the audit data stored in S3"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${each.key}-oracle-database-audit/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "s3-stream"
      serialization_library = "org.apache.hadoop.hive.serde2.OpenCSVSerde"

      parameters = {
        # ignore the first line of the file
        "skip.header.line.count" : 1
      }
    }

    columns {
      name = "DATE_TIME"
      type = "string"
    }

    columns {
      name = "OUTCOME"
      type = "string"
    }

    columns {
      name = "INTERACTION_PARAMETERS"
      type = "string"

    }

    columns {
      name = "USER_ID"
      type = "string"
    }

    columns {
      name = "SPG_USERNAME"
      type = "string"
    }

    columns {
      name = "CLIENT_DB"
      type = "string"
    }

    columns {
      name = "CLIENT_BUSINESS_INTERACT_CODE"
      type = "string"
    }

  }
}

module "s3_bucket_athena_output" {
  count               = contains(local.audit_owners, local.environment) ? 1 : 0
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"
  bucket_name         = "delius-core-${local.environment}-athena-output"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  custom_kms_key      = data.aws_kms_key.general_shared.arn
  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 365
      }
    }
  ]

  tags = local.tags
}

resource "aws_athena_database" "this" {
  count  = contains(local.audit_owners, local.environment) ? 1 : 0
  name   = "audit_owner_db_${local.environment}"
  bucket = module.s3_bucket_athena_output[0].bucket.bucket
}


resource "aws_athena_workgroup" "this" {
  count = contains(local.audit_owners, local.environment) ? 1 : 0
  name  = "audit-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3_bucket_athena_output[0].bucket.bucket}/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = data.aws_kms_key.general_shared.arn
      }
    }
  }
}
