module "github_audit_log_athena_results" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=474f27a3f9bf542a8826c76fb049cc84b5cf136f" # v8.2.1

  bucket_prefix = "github-audit-log-athena-results-"
  providers = {
    aws.bucket-replication = aws
  }
  tags = local.tags
}

resource "aws_athena_workgroup" "github_auditlog" {
  name = "github-auditlog-wg"

  configuration {
    result_configuration {
      output_location = "s3://${module.github_audit_log_athena_results.bucket.id}/results/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = data.aws_kms_key.github_auditlog.arn
      }
    }

    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    bytes_scanned_cutoff_per_query     = 10000000000 # 10GB
    requester_pays_enabled             = false
  }

  state = "ENABLED"
  tags  = local.tags
}

resource "aws_glue_catalog_database" "github_auditlog" {
  name        = "github_auditlog"
  description = "Stores metadata for querying GitHub audit log events via Athena"
  tags        = local.tags
}

resource "aws_iam_role" "glue_github_auditlog_crawler" {
  name = "glue-github-auditlog-crawler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "glue.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

data "aws_kms_key" "github_auditlog" {
  key_id = "alias/GitHubCloudTrailOpenEvent"
}

resource "aws_iam_role_policy" "glue_github_auditlog_policy" {
  role = aws_iam_role.glue_github_auditlog_crawler.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3ReadAccess",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${module.github-cloudtrail-auditlog.github_auditlog_s3bucket}",
          "arn:aws:s3:::${module.github-cloudtrail-auditlog.github_auditlog_s3bucket}/*"
        ]
      },
      {
        Sid    = "AllowGlueCatalogAccess",
        Effect = "Allow",
        Action = [
          "glue:CreateTable",
          "glue:GetTable",
          "glue:UpdateTable",
          "glue:GetDatabase",
          "glue:UpdateDatabase",
          "glue:BatchGetPartition",
          "glue:BatchCreatePartition",
          "glue:GetPartition",
          "glue:CreatePartition",
          "glue:UpdatePartition"
        ],
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogging",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${local.aws_region}:${local.account_id}:log-group:/aws-glue/crawlers:*"
      },
      {
        Sid    = "AllowKMSEncryptDecrypt",
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = data.aws_kms_key.github_auditlog.arn
      }
    ]
  })
}

resource "aws_glue_crawler" "github_auditlog" {
  name          = "github-auditlog-crawler"
  role          = aws_iam_role.glue_github_auditlog_crawler.arn
  database_name = aws_glue_catalog_database.github_auditlog.name

  s3_target {
    path = "s3://${module.github-cloudtrail-auditlog.github_auditlog_s3bucket}/"
    exclusions = [
      "2024/*",
      "2025/01/*",
      "2025/02/*",
      "2025/03/*",
      "2025/04/*",
      "2025/05/*",
    ]
  }

  configuration = jsonencode({
    Version = 1.0,
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    },
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
    },
  })

  recrawl_policy {
    recrawl_behavior = "CRAWL_NEW_FOLDERS_ONLY"
  }
  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "LOG"
  }
  schedule = "cron(0 7 * * ? *)"
  tags     = local.tags
}
