resource "aws_glue_catalog_database" "this" {
  name = "glue-audit-db-${var.env_name}"
}

resource "aws_glue_catalog_table" "this" {
  #   for_each = var.audit_main_account ? toset([for account in local.audit_accounts[var.env_name] : account]) : ([])
  # for_each = var.audit_main_account ? toset([for env in local.audit_envs[join("-", ["delius-core", var.account_info.mp_environment])] : env]) : toset([])
  database_name = aws_glue_catalog_database.this.name
  name          = "audit-table-${var.env_name}"
  description   = "table containing the audit data stored in S3"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${var.env_name}-oracle-database-audit/"
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

resource "aws_athena_database" "example" {
  name   = "athena_audit_db_${var.env_name}"
  bucket = module.s3_bucket_athena_output.bucket.bucket
}

resource "aws_athena_data_catalog" "this" {
  for_each    = { for index, value in lookup(local.audit_share_map, var.env_name, []) : index => value }
  name        = "athena-audit-data-catalog-${each.value.env}"
  description = "Audit data catalog for ${each.value.env}"
  type        = "GLUE"

  parameters = {
    "catalog-id" = var.platform_vars.environment_management.account_ids[each.value.account]
    # "catalog-id" = var.account_info.id
  }


  tags = {
    Name = "athena-audit-data-catalog-${each.value.env}"
  }
}


module "s3_bucket_athena_output" {
  source              = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"
  bucket_name         = "delius-core-${var.env_name}-athena-output"
  versioning_enabled  = false
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  custom_kms_key      = var.account_config.kms_keys.general_shared
  providers = {
    aws.bucket-replication = aws.bucket-replication
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

  tags = var.tags
}
