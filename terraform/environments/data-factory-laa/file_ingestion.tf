module "file_ingestion" {
  source = "./modules/file-ingestion"
  providers = {
    aws.bucket-replication = aws
  }

  database_name = "raw"
  kms_key_arn   = aws_kms_key.data_lake_kms_key.arn
}

# Role to allow uploading of files to the file uploads bucket
# Will be assumable by the SSO role for the data engineering team
resource "aws_iam_role" "file_uploads_role" {
  name = "file-uploads-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          AWS = "arn:aws:iam::766696030771:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-data-eng_9e1f6f5fda83364d"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "file_uploads_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      module.file_ingestion.file_uploads_bucket_arn,
      "${module.file_ingestion.file_uploads_bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.data_lake_kms_key.arn]
  }
}

resource "aws_iam_role_policy" "file_uploads_role_policy" {
  name   = "file-uploads-role-policy"
  role   = aws_iam_role.file_uploads_role.id
  policy = data.aws_iam_policy_document.file_uploads_role_policy.json
}


resource "aws_lakeformation_permissions" "file_uploads_role_permissions_db" {
  permissions = [
    "CREATE_TABLE",
    "DESCRIBE"
  ]
  principal = module.file_ingestion.lambda_role_arn

  database {
    name = "raw"
  }
}

resource "aws_lakeformation_permissions" "file_uploads_role_permissions_table" {
  permissions = [
    "SELECT",
    "DESCRIBE",
    "ALTER",
    "DROP",
    "INSERT",
    "DELETE"
  ]
  principal = module.file_ingestion.lambda_role_arn

  table {
    database_name = "raw"
    wildcard      = true
  }
}
