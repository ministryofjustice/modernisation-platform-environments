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
    }

    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true
    bytes_scanned_cutoff_per_query     = "1000000000" # 1GB, adjust as needed
    requester_pays_enabled             = false
  }

  state = "ENABLED"

  tags = local.tags
}

resource "aws_glue_catalog_database" "github_auditlog" {
  name = "github_auditlog"

  description = "Stores metadata for querying GitHub audit log events via Athena"

  tags = local.tags
}

# IAM Role that allows Glue to read from S3 and write to the catalog
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

# Minimal policy: S3 read + Glue write
resource "aws_iam_role_policy" "glue_github_auditlog_policy" {
  role = aws_iam_role.glue_github_auditlog_crawler.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
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
        Effect = "Allow",
        Action = [
          "glue:CreateTable",
          "glue:GetTable",
          "glue:UpdateTable",
          "glue:GetDatabase",
          "glue:UpdateDatabase"
        ],
        Resource = "*"
      }
    ]
  })
}

# Glue Crawler
resource "aws_glue_crawler" "github_auditlog" {
  name = "github-auditlog-crawler"

  role = aws_iam_role.glue_github_auditlog_crawler.arn

  database_name = aws_glue_catalog_database.github_auditlog.name

  s3_target {
    path = "s3://${module.github-cloudtrail-auditlog.github_auditlog_s3bucket}/"
  }

  # Configuration to optimize schema inference and control partitions
  configuration = jsonencode({
    Version = 1.0,
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    },
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
    }
  })

  tags = local.tags
}
