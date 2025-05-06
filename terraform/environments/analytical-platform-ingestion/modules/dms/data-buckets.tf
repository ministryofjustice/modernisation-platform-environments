# S3 bucket to store lambda code/packages
#trivy:ignore:AVD-AWS-0089: No logging required
resource "aws_s3_bucket" "lambda" {
  #checkov:skip=CKV_AWS_18:Logging not needed
  #checkov:skip=CKV2_AWS_61:Lifecycle configuration not needed
  #checkov:skip=CKV2_AWS_62:Versioning,event notifications,logging not needed
  #checkov:skip=CKV_AWS_144:Cross-region replication not required
  bucket_prefix = "${var.db}-lambda-fns-"

  tags = var.tags
  # Force destroy is safe here, as the bucket is repopulated on terraform run
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "lambda" {
  bucket = aws_s3_bucket.lambda.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambda" {
  bucket = aws_s3_bucket.lambda.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.bucket_kms.key_arn
      sse_algorithm     = "aws:kms"
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
  #checkov:skip=CKV_AWS_18:Logging not needed
  #checkov:skip=CKV_AWS_21:Versioning not needed
  #checkov:skip=CKV2_AWS_61:Lifecycle configuration not needed
  #checkov:skip=CKV_AWS_144:Cross-region replication not required
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

resource "aws_s3_bucket_server_side_encryption_configuration" "landing" {
  bucket = aws_s3_bucket.landing.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.bucket_kms.key_arn
      sse_algorithm     = "aws:kms"
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
# This can be passed in from outside the module
# but in that case it is assumed all related aws_s3_bucket_* resources are being managed externally
#trivy:ignore:AVD-AWS-0089: No logging required
resource "aws_s3_bucket" "raw_history" {
  #checkov:skip=CKV2_AWS_6:False positive, Public access block attached via data.raw_history instead of resource
  #checkov:skip=CKV_AWS_18:Logging not needed
  #checkov:skip=CKV_AWS_21:Versioning not needed
  #checkov:skip=CKV2_AWS_61:Lifecycle configuration not needed
  #checkov:skip=CKV2_AWS_62:Versioning,event notifications,logging not needed
  #checkov:skip=CKV_AWS_144:Cross-region replication not required
  #checkov:skip=CKV_AWS_145:False positive, KMS envryption attached via data.raw_history instead of resource
  count         = length(var.output_bucket) > 0 ? 0 : 1
  bucket_prefix = "${var.db}-raw-history-"
}

data "aws_s3_bucket" "raw_history" {
  bucket = length(var.output_bucket) > 0 ? var.output_bucket : aws_s3_bucket.raw_history[0].id
}

resource "aws_s3_bucket_ownership_controls" "raw_history" {
  count  = length(var.output_bucket) > 0 ? 0 : 1
  bucket = data.aws_s3_bucket.raw_history.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "raw_history" {
  count  = length(var.output_bucket) > 0 ? 0 : 1
  bucket = data.aws_s3_bucket.raw_history.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#trivy:ignore:AVD-AWS-0090: Versioning not needed
resource "aws_s3_bucket_versioning" "raw_history" {
  count  = length(var.output_bucket) > 0 ? 0 : 1
  bucket = data.aws_s3_bucket.raw_history.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw_history" {
  count  = length(var.output_bucket) > 0 ? 0 : 1
  bucket = data.aws_s3_bucket.raw_history.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.bucket_kms.key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Invalid bucket
#trivy:ignore:AVD-AWS-0089: No logging required
resource "aws_s3_bucket" "invalid" {
  #checkov:skip=CKV_AWS_18:Logging not needed
  #checkov:skip=CKV_AWS_21:Versioning not needed
  #checkov:skip=CKV2_AWS_61:Lifecycle configuration not needed
  #checkov:skip=CKV2_AWS_62:Versioning,event notifications,logging not needed
  #checkov:skip=CKV_AWS_144:Cross-region replication not required
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

resource "aws_s3_bucket_server_side_encryption_configuration" "invalid" {
  bucket = aws_s3_bucket.invalid.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.bucket_kms.key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Bucket to store premigration-assessment
#trivy:ignore:AVD-AWS-0089: No logging required
resource "aws_s3_bucket" "premigration_assessment" {
  #checkov:skip=CKV_AWS_18:Logging not needed
  #checkov:skip=CKV_AWS_21:Versioning not needed
  #checkov:skip=CKV2_AWS_61:Lifecycle configuration not needed
  #checkov:skip=CKV2_AWS_62:Versioning,event notifications,logging not needed
  #checkov:skip=CKV_AWS_144:Cross-region replication not required
  count         = var.create_premigration_assessement_resources ? 1 : 0
  bucket_prefix = "${var.db}-pma-"
}

resource "aws_s3_bucket_ownership_controls" "premigration_assessment" {
  count  = var.create_premigration_assessement_resources ? 1 : 0
  bucket = aws_s3_bucket.premigration_assessment[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "premigration_assessment" {
  count  = var.create_premigration_assessement_resources ? 1 : 0
  bucket = aws_s3_bucket.premigration_assessment[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#trivy:ignore:AVD-AWS-0090: Versioning not needed
resource "aws_s3_bucket_versioning" "premigration_assessment" {
  count  = var.create_premigration_assessement_resources ? 1 : 0
  bucket = aws_s3_bucket.premigration_assessment[0].id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "premigration_assessment" {
  count  = var.create_premigration_assessement_resources ? 1 : 0
  bucket = aws_s3_bucket.premigration_assessment[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.bucket_kms.key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}
