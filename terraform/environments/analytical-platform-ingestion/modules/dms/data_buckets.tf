# S3 bucket to store lambda code/packages
#trivy:ignore:AVD-AWS-0089: No logging required
resource "aws_s3_bucket" "lambda" {
  bucket_prefix = "${var.db}-lambda-functions-"

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "lambda" {
  bucket = aws_s3_bucket.lambda.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#trivy:ignore:AVD-AWS-0132: Uses AES256 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "lambda" {
  bucket = aws_s3_bucket.lambda.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "lambda" {
  bucket = aws_s3_bucket.lambda.id
  versioning_configuration {
    status = "Enabled"
  }
}


# S3 bucket - Landing
#trivy:ignore:AVD-AWS-0089: No logging required
resource "aws_s3_bucket" "landing" {
  bucket_prefix = "${var.db}-landing-"
}

resource "aws_s3_bucket_ownership_controls" "landing" {
  bucket = aws_s3_bucket.landing.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "landing" {
  bucket = aws_s3_bucket.landing.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#trivy:ignore:AVD-AWS-0090: Versioning not needed
resource "aws_s3_bucket_versioning" "landing" {
  bucket = aws_s3_bucket.landing.id
  versioning_configuration {
    status = "Disabled"
  }
}

#trivy:ignore:AVD-AWS-0132: Uses AES256 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "landing" {
  bucket = aws_s3_bucket.landing.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lambda permission to allow landing bucket to invoke validation lambda
resource "aws_lambda_permission" "allow_landing_bucket_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.validation_lambda_function.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.landing.arn
}

# S3 bucket notification to trigger validation lambda
resource "aws_s3_bucket_notification" "landing" {
  bucket = aws_s3_bucket.landing.bucket

  lambda_function {
    lambda_function_arn = module.validation_lambda_function.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# Bucket to store validated data
#trivy:ignore:AVD-AWS-0089: No logging required
resource "aws_s3_bucket" "raw_history" {
  bucket_prefix = "${var.db}-raw-history-"
}

resource "aws_s3_bucket_ownership_controls" "raw_history" {
  bucket = aws_s3_bucket.raw_history.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "raw_history" {
  bucket = aws_s3_bucket.raw_history.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#trivy:ignore:AVD-AWS-0090: Versioning not needed
resource "aws_s3_bucket_versioning" "raw_history" {
  bucket = aws_s3_bucket.raw_history.id
  versioning_configuration {
    status = "Disabled"
  }
}

#trivy:ignore:AVD-AWS-0132: Uses AES256 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "raw_history" {
  bucket = aws_s3_bucket.raw_history.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Invalid bucket
#trivy:ignore:AVD-AWS-0089: No logging required
resource "aws_s3_bucket" "invalid" {
  bucket_prefix = "${var.db}-invalid-"
}

resource "aws_s3_bucket_ownership_controls" "invalid" {
  bucket = aws_s3_bucket.invalid.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "invalid" {
  bucket = aws_s3_bucket.invalid.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#trivy:ignore:AVD-AWS-0090: Versioning not needed
resource "aws_s3_bucket_versioning" "invalid" {
  bucket = aws_s3_bucket.invalid.id
  versioning_configuration {
    status = "Disabled"
  }
}

#trivy:ignore:AVD-AWS-0132: Uses AES256 encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "invalid" {
  bucket = aws_s3_bucket.invalid.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
