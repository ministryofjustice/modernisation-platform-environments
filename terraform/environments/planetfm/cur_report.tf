resource "aws_cur_report_definition" "cur_planetfm" {
  provider                   = aws.us-east-1
  report_name                = "planetfm-cur-report-definition"
  time_unit                  = "HOURLY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = ["RESOURCES", "SPLIT_COST_ALLOCATION_DATA"]
  s3_bucket                  = module.csr-report-bucket.bucket.id
  s3_region                  = "eu-west-2"
  additional_artifacts       = ["ATHENA"]
  report_versioning          = "OVERWRITE_REPORT"
  s3_prefix                  = "cur" 
}

module "csr-report-bucket" {
    source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.1.0"

    bucket_prefix = "planetfm"
    versioning_enabled = false
    bucket_policy = [data.aws_iam_policy_document.cur_bucket_policy.json]
    force_destroy  = true
    replication_enabled = false
    sse_algorithm = "AES256"
    providers = {
        aws.bucket-replication = aws
    }

    tags = merge(local.tags, {
        Name = lower(format("cur-report-bucket-%s-%s", local.application_name, local.environment))
    })
}

data "aws_iam_policy_document" "cur_bucket_policy" {
    statement {
        sid       = "EnsureBucketOwnedByAccountForCURDelivery"
        effect    = "Allow"
        resources = [module.csr-report-bucket.bucket.arn]

        actions = [
        "s3:GetBucketAcl",
        "s3:GetBucketPolicy",
        ]

        condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values   = ["arn:aws:cur:us-east-1:${local.environment_management.account_ids[terraform.workspace]}:definition/*"]
        }

        condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = ["${local.environment_management.account_ids[terraform.workspace]}"]
        }

        principals {
        type        = "Service"
        identifiers = ["billingreports.amazonaws.com"]
        }
    }

    statement {
        sid       = "GrantAccessToDeliverCURFiles"
        effect    = "Allow"
        resources = ["${module.csr-report-bucket.bucket.arn}/*"]
        actions   = ["s3:PutObject"]

        condition {
        test     = "StringEquals"
        variable = "aws:SourceArn"
        values   = ["arn:aws:cur:us-east-1:${local.environment_management.account_ids[terraform.workspace]}:definition/*"]
        }

        condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = ["${local.environment_management.account_ids[terraform.workspace]}"]
        }

        principals {
        type        = "Service"
        identifiers = ["billingreports.amazonaws.com"]
        }
    }
}

resource "aws_athena_database" "cur" {
    name = "cur"
    bucket = module.csr-report-bucket.bucket.id
    encryption_configuration {
        encryption_option = "SSE_S3"
    }
}

resource "aws_athena_workgroup" "cur" {
    name = "cur"
    configuration {
        enforce_workgroup_configuration = true
        publish_cloudwatch_metrics_enabled = true

        engine_version {
            selected_engine_version = "Athena engine version 3"    
        }
        result_configuration {
            output_location = "s3://${module.csr-report-bucket.bucket.id}/output/"
        }
    }
}

resource "aws_glue_catalog_table" "cur" {
    name = "cur-table"
    database_name = aws_athena_database.cur.name
    table_type = "EXTERNAL_TABLE"

    storage_descriptor {
        input_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
        output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
        location = "s3://${module.csr-report-bucket.bucket.id}/cur/"
        ser_de_info {
            serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
            parameters = {
            "serialization.format" = 1
            }
        }
    }
}
