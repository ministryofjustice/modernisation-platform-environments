# Shared S3 bucket for Lambda layer delivery
# Note: upload lambda_delivery/cloudwatch_sns_layer/layerV1.zip manually before first apply
# See: https://dsdmoj.atlassian.net/wiki/spaces/LDD/pages/5975606239/Build+Layered+Function+for+Lambda

resource "aws_s3_bucket" "maat_shared" {
  bucket = "${local.application_name}-${local.environment}-shared"

  tags = merge(local.tags,
    {
      Name = "${local.application_name}-${local.environment}-shared"
    }
  )
}

resource "aws_s3_object" "folder" {
  bucket = aws_s3_bucket.maat_shared.bucket
  for_each = {
    for index, name in local.lambda_folder_name :
    name => index == 0 ? "${name}/" : "lambda_delivery/${name}/"
  }

  key = each.value
}

resource "aws_s3_bucket_public_access_block" "maat_shared" {
  bucket                  = aws_s3_bucket.maat_shared.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "maat_shared" {
  bucket = aws_s3_bucket.maat_shared.id

  versioning_configuration {
    status = "Enabled"
  }
}
