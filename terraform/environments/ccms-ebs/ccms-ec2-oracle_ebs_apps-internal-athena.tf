
# S3 bucket with data
data "aws_s3_bucket" "data_bucket" {
  bucket = "ccms-ebs-development-logging"
}

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
      "Sid": "AllowGlueAccessToS3"
    }]
  })
}

# IAM Policy Attachment
resource "aws_iam_role_policy_attachment" "glue_policy_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Glue Catalog Database
resource "aws_glue_catalog_database" "logs_database" {
  name = "internal_loadbalancer_access_logs"
}

# Glue Crawler
resource "aws_glue_crawler" "internal_lb_logs_crawler" {
  name          = "internal-lb-logs-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws.glue_catalog_database.logs_database.name
  table_prefix  = "internal_lb_logs"

  s3_target {
    path = "s3://${data.aws_s3_bucket.data_bucket.bucket}/ebsapps-internal-lb/"
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
    result_configuration {
      output_location = "s3://${data.aws_s3_bucket.data_bucket.bucket}/results/"
    }
  }
}
