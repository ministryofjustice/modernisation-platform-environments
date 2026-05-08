# Shared S3 bucket for Lambda layer delivery
# Note: upload lambda_delivery/cloudwatch_sns_layer/layerV1.zip manually before first apply
# See: https://dsdmoj.atlassian.net/wiki/spaces/LDD/pages/5975606239/Build+Layered+Function+for+Lambda
module "s3-bucket-shared" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=474f27a3f9bf542a8826c76fb049cc84b5cf136f"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix       = "${local.application_name}-${local.environment}-shared"
  replication_enabled = false
  versioning_enabled  = true
  force_destroy       = false
  ownership_controls  = "BucketOwnerEnforced"

  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-shared"
  })
}
