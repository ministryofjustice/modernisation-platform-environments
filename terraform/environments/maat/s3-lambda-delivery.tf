# Shared S3 bucket for Lambda layer delivery
# Note: upload lambda_delivery/cloudwatch_sns_layer/layerV1.zip manually before first apply
# See: https://dsdmoj.atlassian.net/wiki/spaces/LDD/pages/5975606239/Build+Layered+Function+for+Lambda

moved {
  from = aws_s3_bucket.maat_shared
  to   = module.s3-bucket-shared.aws_s3_bucket.default
}

moved {
  from = aws_s3_bucket_public_access_block.maat_shared
  to   = module.s3-bucket-shared.aws_s3_bucket_public_access_block.default
}

moved {
  from = aws_s3_bucket_versioning.maat_shared
  to   = module.s3-bucket-shared.aws_s3_bucket_versioning.default
}

module "s3-bucket-shared" {
  # v9.0.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/9facf9fc8f8b8e3f93ffbda822028534b9a75399
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"

  bucket_name        = "${local.application_name}-${local.environment}-shared"
  versioning_enabled = true
  replication_enabled = false
  replication_region  = "eu-west-2"

  providers = {
    aws.bucket-replication = aws
  }

  tags = local.tags
}

resource "aws_s3_object" "folder" {
  bucket = module.s3-bucket-shared.bucket.id
  for_each = {
    for index, name in local.lambda_folder_name :
    name => index == 0 ? "${name}/" : "lambda_delivery/${name}/"
  }

  key = each.value
}
