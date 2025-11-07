#####################################################################################
################## S3 Bucket for Lambda Layer Dependencies ##########################
#####################################################################################
resource "aws_s3_bucket" "lambda_layer_dependencies" {
  bucket = "lambda-layer-dependencies-${local.environment}-bucket"

  tags = merge(
    local.tags,
    { Name = "lambda-layer-dependencies-${local.environment}" }
  )
}

resource "aws_s3_object" "lambda_layer_zip" {
  bucket      = aws_s3_bucket.lambda_layer_dependencies.bucket
  key         = "cwa_extract_lambda/lambda_dependencies.zip"
  source      = "layers/lambda_dependencies.zip"
  source_hash = filemd5("layers/lambda_dependencies.zip")
}

# resource "aws_s3_object" "oracledb_lambda_layer_zip" {
#   count       = local.environment == "test" ? 1 : 0
#   bucket      = aws_s3_bucket.lambda_layer_dependencies.bucket
#   key         = "cwa_extract_lambda/oracledb_lambda_dependencies.zip"
#   source      = "layers/oracledb_lambda_dependencies.zip"
#   source_hash = filemd5("layers/oracledb_lambda_dependencies.zip")
# }

resource "aws_s3_bucket_public_access_block" "lambda_layer_dependencies" {
  bucket                  = aws_s3_bucket.lambda_layer_dependencies.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "lambda_layer_dependencies" {
  bucket = aws_s3_bucket.lambda_layer_dependencies.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "lambda_layer_dependencies" {
  bucket = aws_s3_bucket.lambda_layer_dependencies.id
  versioning_configuration {
    status = "Enabled"
  }
}

#####################################################################################
######################## S3 Bucket for Extracted Data ###############################
#####################################################################################

resource "aws_s3_bucket" "data" {
  bucket = "${local.application_name_short}-${local.environment}-cwa-extract-data"

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-cwa-extract-data" }
  )
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "data" {
  bucket = aws_s3_bucket.data.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "log/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}

#####################################################################################
######################## S3 Bucket for Wallet Files ###############################
#####################################################################################

resource "aws_s3_bucket" "wallet_files" {
  bucket = "${local.application_name_short}-${local.environment}-wallet-files"

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-wallet-files" }
  )
}

resource "aws_s3_bucket_public_access_block" "wallet_files" {
  bucket                  = aws_s3_bucket.wallet_files.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "wallet_files" {
  bucket = aws_s3_bucket.wallet_files.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "wallet_files" {
  bucket = aws_s3_bucket.wallet_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "wallet_files" {
  bucket = aws_s3_bucket.wallet_files.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "log/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
}
