# IAM Role for Glue Crawler
resource "aws_iam_role" "glue_role" {
  name = "glue-crawler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "glue.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = "AllowGlueAccessToS3",
      Condition = {
        StringEquals = {
          "aws:SourceAccount": data.aws_caller_identity.current.account_id
        },
        ArnLike = {
          "aws:SourceArn": "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:crawler/${aws_glue_crawler.internal_lb_logs_crawler.name}"
        }
      }
    }]
  })

  depends_on = [ aws_glue_crawler.internal_lb_logs_crawler ]
}

# Custom IAM policy for Glue
resource "aws_iam_role_policy" "glue_policy" {
  name = "glue-crawler-custom-policy"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:GetTable",
          "glue:GetTables",
          "glue:UpdateTable",
          "glue:CreateTable",
          "glue:DeleteTable"
        ]
        Resource = [
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_database.logs_database.name}",
          "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.logs_database.name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          data.aws_s3_bucket.data_bucket.arn,
          "${module.s3-bucket-logging.bucket.id}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws-glue/crawlers:*"
        ]
      }
    ]
  })
}

# Glue Security Configuration
resource "aws_glue_security_configuration" "crawler_security_config" {
  name = "internal-lb-logs-security-config"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-S3"
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn = data.aws_kms_key.ebs_shared.key_id
    }

    s3_encryption {
      s3_encryption_mode = "SSE-S3"
    }
  }
}

# Glue Catalog Database
resource "aws_glue_catalog_database" "logs_database" {
  name = "internal_loadbalancer_access_logs"
}

# Glue Crawler
resource "aws_glue_crawler" "internal_lb_logs_crawler" {
  name          = "internal-lb-logs-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.logs_database.name
  table_prefix  = "internal_lb_logs"

  s3_target {
    path = "s3://${module.s3-bucket-logging.bucket.id}/ebsapps-internal-lb/"
  }

  schema_change_policy {
    delete_behavior = "LOG"
  }

  configuration = jsonencode({
    Version = 1.0,
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })
}

resource "aws_athena_workgroup" "internal_lb_logs_workgroup" {
  name = "internal-lb-logs-workgroup"

  configuration {
    enforce_workgroup_configuration = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.s3-bucket-logging.bucket.id}/output/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
