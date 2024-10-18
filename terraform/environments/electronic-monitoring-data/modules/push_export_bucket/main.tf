terraform {
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
  }
  required_version = "~> 1.0"
}

module "this-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${var.local_bucket_prefix}-export-${var.export_destination}-"
  versioning_enabled = false

  # to disable ACLs in preference of BucketOwnership controls as per https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/ set:
  ownership_controls = "BucketOwnerEnforced"
  acl                = "private"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below variable and providers configuration is only relevant if 'replication_enabled' is set to true
  # replication_region                       = "eu-west-2"
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    # Leave this provider block in even if you are not using replication
    aws.bucket-replication = aws
  }
  log_buckets = tomap({
    "log_bucket_name" : var.logging_bucket.bucket.id,
    "log_bucket_arn" : var.logging_bucket.bucket.arn,
    "log_bucket_policy" : var.logging_bucket.bucket_policy.policy,
  })
  log_prefix                = "logs/${var.local_bucket_prefix}-export-${var.export_destination}/"
  log_partition_date_source = "EventTime"

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      expiration = {
        days = 7
      }
    }
  ]

  tags = merge(
    var.local_tags,
    { export_destination = var.export_destination }
  )
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket-${var.export_destination}"
  action        = "lambda:InvokeFunction"
  function_name = module.push_lambda.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.this-bucket.bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.this-bucket.bucket.id

  lambda_function {
    lambda_function_arn = module.push_lambda.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

#------------------------------------------------------------------------------
# Push lambda 
#------------------------------------------------------------------------------

module "push_lambda" {
  source                  = "../lambdas"
  function_name           = "push_data_export_to_${var.export_destination}"
  image_name              = "push_data_export"
  is_image                = true
  role_name               = aws_iam_role.push_lambda.name
  role_arn                = aws_iam_role.push_lambda.arn
  memory_size             = 1024
  timeout                 = 900
  core_shared_services_id = var.core_shared_services_id
  production_dev          = var.production_dev
  environment_variables = {
    DESTINATION_BUCKET = var.destination_bucket_id
  }
}

#------------------------------------------------------------------------------
# Push lambda iam role
#------------------------------------------------------------------------------

resource "aws_iam_role" "push_lambda" {
  name               = "${var.export_destination}_export_bucket_files"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "push_lambda" {
  statement {
    sid    = "S3PermissionsForExportBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.this-bucket.bucket.arn}/*",
    ]
  }

  statement {
    sid    = "S3PermissionsForDestinationBucket"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${var.destination_bucket_id}/*",
    ]
  }
}

resource "aws_iam_policy" "push_lambda" {
  name        = "${var.export_destination}_export_bucket_files_policy"
  description = "Policy for Lambda to create presigned url for unzipped file from S3"
  policy      = data.aws_iam_policy_document.push_lambda.json
}

resource "aws_iam_role_policy_attachment" "push_lambda" {
  role       = aws_iam_role.push_lambda.name
  policy_arn = aws_iam_policy.push_lambda.arn
}
