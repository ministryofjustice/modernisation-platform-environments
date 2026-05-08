module "s3_bucket" {
  for_each = {
    for key, value in local.bucket_configuration : key => value
  }
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.13.0"

  bucket_prefix = each.value.bucket_prefix

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true

  lifecycle_rule = each.value.lifecycle_rule
}

module "s3_bucket_notification" {
  source  = "terraform-aws-modules/s3-bucket/aws//modules/notification"
  version = "5.13.0"

  bucket     = module.s3_bucket["unscanned"].s3_bucket_id
  bucket_arn = module.s3_bucket["unscanned"].s3_bucket_arn

  sqs_notifications = {
    unscanned = {
      queue_arn     = module.sqs_unscanned_s3_notifications.queue_arn
      events        = ["s3:ObjectCreated:*"]
      filter_prefix = "incoming/"
    }
  }
}