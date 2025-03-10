#S3 bucket to store source metadata
#trivy:ignore:AVD-AWS-0089: No logging required
resource "aws_s3_bucket" "validation_metadata" {
  bucket_prefix = "${var.db}-metadata-"

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "validation_metadata" {
  bucket = aws_s3_bucket.validation_metadata.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "validation_metadata" {
  bucket = aws_s3_bucket.validation_metadata.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#trivy:ignore:AVD-AWS-0090: Versioning not needed
resource "aws_s3_bucket_versioning" "validation_metadata" {
  bucket = aws_s3_bucket.validation_metadata.id
  versioning_configuration {
    status = "Enabled"
  }
}

#trivy:ignore:AVD-AWS-0132: Uses AES256 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "validation_metadata" {
  bucket = aws_s3_bucket.validation_metadata.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


data "aws_iam_policy_document" "metadata_generator_lambda_function" {
  # Lambda can upload files to the metadata bucket
  statement {
    actions = [
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.validation_metadata.arn,
      "${aws_s3_bucket.validation_metadata.arn}/*",
    ]
  }

  # Lambda can reprocess data in the invalid bucket
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:DeleteObject"
    ]

    resources = [
      aws_s3_bucket.invalid.arn,
      "${aws_s3_bucket.invalid.arn}/*"
    ]
  }

  # Lambda can reprocess data in the invalid bucket
  statement {
    actions = [
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.landing.arn,
      "${aws_s3_bucket.landing.arn}/*"
    ]
  }

  # Lambda can get the secret value for the data source from AWS Secrets Manager
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.dms_source.arn
    ]
  }

  # Lambda can create glue database/table
  # checkov:skip=CKV_AWS_111: The resource is not publicly accessible
  # checkov:skip=CKV_AWS_356: Required glue permissions for the lambda
  statement {
    actions = [
      "glue:GetDatabase",
      "glue:CreateDatabase",
      "glue:GetTable",
      "glue:CreateTable",
      "glue:UpdateTable",
    ]

    resources = ["*"]
  }
}

# Create security group for Lambda function
#trivy:ignore:AVD-AWS-0104: Allow all egress traffic
resource "aws_security_group" "metadata_generator_lambda_function" {
  #checkov:skip=CKV_AWS_382: Allow all egress traffic
  name        = "${var.db}-metadata-generator-lambda-function"
  vpc_id      = var.vpc_id
  description = "Security group for Lambda function to generate metadata for ${var.db} DMS data output"

  egress {
    description = "Allow all egress traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "metadata_generator" {
  # Commit hash for v7.20.1
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda?ref=84dfbfddf9483bc56afa0aff516177c03652f0c7"

  function_name           = "${var.db}-metadata-generator"
  description             = "Lambda to generate metadata for ${var.db} DMS data output"
  handler                 = "main.handler"
  runtime                 = "python3.12"
  memory_size             = 512
  timeout                 = 60
  architectures           = ["x86_64"]
  build_in_docker         = true
  docker_image            = "test-dms"
  store_on_s3             = true
  s3_bucket               = aws_s3_bucket.lambda.bucket
  s3_object_storage_class = "STANDARD"
  s3_prefix               = "metadata-generator/"

  # Lambda function will be attached to the VPC to access the source database
  vpc_security_group_ids = [aws_security_group.metadata_generator_lambda_function.id]
  vpc_subnet_ids         = var.dms_replication_instance.subnet_ids
  attach_network_policy  = true


  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.metadata_generator_lambda_function.json

  environment_variables = {
    ENVIRONMENT        = "sandbox"
    DB_SECRET_ARN      = aws_secretsmanager_secret.dms_source.arn
    METADATA_BUCKET    = aws_s3_bucket.validation_metadata.bucket
    LANDING_BUCKET     = aws_s3_bucket.landing.bucket
    INVALID_BUCKET     = aws_s3_bucket.invalid.bucket
    RAW_HISTORY_BUCKET = aws_s3_bucket.raw_history.bucket
    DB_OBJECTS         = jsonencode(["TEST_DATA"])
    DB_SCHEMA_NAME     = "ADMIN"
  }

  source_path = [{
    path             = "${path.module}/lambda-functions/metadata_generator/main.py"
    pip_tmp_dir      = "${path.module}/lambda-functions/metadata_generator/fixtures"
    pip_requirements = "${path.module}/lambda-functions/metadata_generator/requirements.txt"
  }]

  tags = var.tags
}
