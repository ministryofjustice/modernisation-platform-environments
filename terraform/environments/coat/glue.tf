#checkov:skip=CKV_AWS_355:Glue Crawlers do not support security_configuration
resource "aws_glue_catalog_database" "cur_v2_database" {
  name = "cur_v2_database"
}

resource "aws_iam_role" "glue_cur_role" {
  name = "glue-cur-role"

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

resource "aws_iam_role_policy_attachment" "glue_service_role_policy" {
  role       = aws_iam_role.glue_cur_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_s3_policy" {
  role = aws_iam_role.glue_cur_role.id
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
      }
    ]
  })
}

resource "aws_glue_crawler" "cur_v2_crawler" {
  name          = "cur_v2_crawler"
  database_name = aws_glue_catalog_database.cur_v2_database.name
  role          = aws_iam_role.glue_cur_role.arn

  s3_target {
    path = "s3://coat-${local.environment}-cur-v2-hourly/"
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


