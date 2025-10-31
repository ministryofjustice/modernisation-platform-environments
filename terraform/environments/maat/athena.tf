locals {
  account_id = local.environment_management.account_ids[terraform.workspace]
  region     = local.application_data.accounts[local.environment].region
}

### Setup S3 Bucket for Athena Queries ###
module "s3-bucket-athena-queries-output" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=474f27a3f9bf542a8826c76fb049cc84b5cf136f"

  bucket_prefix      = "athena-query-s3-bucket"
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.athena_bucket_policy.json]
  # Enable bucket to be destroyed when not empty
  force_destroy = true
  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region = local.region
  # replication_role_arn = module.s3-bucket-replication-role.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
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
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = merge(local.tags,
    { Name = lower(format("s3-bucket-%s-%s-athena", local.application_name, local.environment)) }
  )
}

data "aws_iam_policy_document" "athena_bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = ["${module.s3-bucket-athena-queries-output.bucket.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["athena.amazonaws.com"]
    }
  }
}

### Setup Athena Queries ###
resource "aws_athena_database" "lb-access-logs" {
  name   = "loadbalancer_access_logs"
  bucket = module.lb-s3-access-logs[0].bucket.id
  encryption_configuration {
    encryption_option = "SSE_S3"
  }
}

resource "aws_athena_named_query" "lb_log_table_query" {
  name     = "${local.application_name}-create-table"
  database = aws_athena_database.lb-access-logs.name
  query = templatefile(
    "${path.module}/templates/create_load_balancer_logs_table.sql",
    {
      bucket     = module.lb-s3-access-logs[0].bucket.id
      account_id = local.account_id
      region     = local.region
    }
  )
}

resource "aws_athena_workgroup" "lb-access-logs" {
  name = "${local.application_name}-lb-access-logs"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-bucket-athena-queries-output.bucket.id}/output/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-lb-access-logs"
    }
  )

}

resource "aws_athena_database" "cloudfront-access-logs" {
  name   = "cloudfront_access_logs"
  bucket = aws_s3_bucket.cloudfront.id
  encryption_configuration {
    encryption_option = "SSE_S3"
  }
}

resource "aws_athena_named_query" "cloudfront_query" {
  name     = "${local.application_name}-create-cloudfront-logs-table"
  database = aws_athena_database.cloudfront-access-logs.name
  query = templatefile(
    "${path.module}/templates/create_cloudfront_logs_table.sql",
    {
      bucket     = aws_s3_bucket.cloudfront.id
      account_id = local.account_id
      region     = local.region
    }
  )
}

resource "aws_athena_workgroup" "cloudfront-logs" {
  name = "${local.application_name}-cloudfront-logs"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-bucket-athena-queries-output.bucket.id}/output/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-cloudfront-access-logs"
    }
  )

}
