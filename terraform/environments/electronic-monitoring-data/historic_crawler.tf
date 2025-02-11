resource "aws_glue_crawler" "iceberg_crawler" {
  database_name = "historic_api_mart"
  name          = "historic_api_mart_crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://emds-test-cadt/data/test/models/domain_name=historic/database_name=historic_api_mart_mock/"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })
}

# IAM role for the crawler
resource "aws_iam_role" "glue_role" {
  name = "historic_api_mart_crawler_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_lakeformation_permissions" "s3_bucket_permissions_de" {
  principal = aws_iam_role.glue_role.arn

  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}


# Attach necessary policies to the role
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Custom policy for S3 access
resource "aws_iam_role_policy" "s3_access" {
  name = "s3_access"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::emds-test-cadt/*",
          "arn:aws:s3:::emds-test-cadt"
        ]
      }
    ]
  })
}
