resource "aws_athena_workgroup" "coat_cur_report" {
  name = "coat_cur_report"

  configuration {
    result_configuration {
      output_location = "s3://coat-${local.environment}-cur-v2-hourly/athena-results/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    enforce_workgroup_configuration = true
    publish_cloudwatch_metrics_enabled = true
  }

  tags = local.tags
}

resource "aws_glue_catalog_database" "cur_v2_database" {
  name = "cur_v2_database"
}

resource "aws_iam_role" "glue_cur_role" {
  name = "glue_cur_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "glue_s3_policy" {
  #checkov:skip=CKV_AWS_355: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
  #checkov:skip=CKV_AWS_290: "Ensure IAM policies does not allow write access without constraints"
  role = aws_iam_role.glue_cur_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:ListBucket"],
        Resource = [
          "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly/*",
          "arn:aws:s3:::coat-${local.environment}-cur-v2-hourly"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = module.cur_s3_kms.key_arn
      },
      {
        Sid    = "GluePermission",
        Effect = "Allow",
        Action = [
          "glue:BatchGetPartition",
          "glue:CreateTable",
          "glue:GetCatalogs",
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:ImportCatalogToGlue",
          "glue:UpdateDatabase",
          "glue:UpdateTable",
          "glue:StartCrawler"
        ],
        Resource = ["*"]
      },
      {
        Sid    = "AthenaAccess",
        Effect = "Allow",
        Action = [
          "athena:GetDatabase",
          "athena:GetDataCatalog",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:GetTableMetadata",
          "athena:GetWorkGroup",
          "athena:ListDatabases",
          "athena:ListDataCatalogs",
          "athena:ListWorkGroups",
          "athena:ListTableMetadata",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution"
        ],
        Resource = ["*"]
      },
      { 
        Sid    = "LoggingAccess",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
          ],
          Resource = ["*"]
        },
    ]
  })
}

resource "aws_glue_crawler" "cur_v2_crawler" {
  #checkov:skip=CKV_AWS_195: "Ensure Glue component has a security configuration associated"
  name          = "cur_v2_crawler"
  database_name = aws_glue_catalog_database.cur_v2_database.name
  role          = aws_iam_role.glue_cur_role.arn

  s3_target {
    path = "s3://coat-${local.environment}-cur-v2-hourly/moj-cost-and-usage-reports/MOJ-CUR-V2-HOURLY/data/"
  }

  configuration = jsonencode({
    Version = 1.0,
    CrawlerOutput = {
      Tables = {
        AddOrUpdateBehavior = "MergeNewColumns"
      }
    }
  })

  schedule = "cron(0 7 * * ? *)"
}
